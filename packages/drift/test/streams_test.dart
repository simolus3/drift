import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/src/runtime/api/runtime_api.dart';
import 'package:drift/src/runtime/executor/stream_queries.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'data/tables/custom_tables.dart';
import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;
  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('streams fetch when the first listener attaches', () async {
    final stream = db.select(db.users).watch();

    verifyNever(executor.runSelect(any, any));

    stream.listen((_) {});
    await pumpEventQueue(times: 1);

    verify(executor.runSelect(any, any)).called(1);
  });

  test('streams fetch when the underlying data changes', () async {
    db.select(db.users).watch().listen((_) {});

    db.markTablesUpdated({db.users});
    await pumpEventQueue(times: 1);

    // twice: Once because the listener attached, once because the data changed
    verify(executor.runSelect(any, any)).called(2);
  });

  test('streams recognize aliased tables', () async {
    final first = db.alias(db.users, 'one');
    final second = db.alias(db.users, 'two');

    db.select(first).watch().listen((_) {});
    await pumpEventQueue(times: 1);

    db.markTablesUpdated({second});
    await pumpEventQueue(times: 1);

    verify(executor.runSelect(any, any)).called(2);
  });

  test('streams emit cached data when a new listener attaches', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));

    final first = db.select(db.users).watch();
    expect(first, emits(isEmpty));

    clearInteractions(executor);

    final second = db.select(db.users).watch();
    expect(second, emits(isEmpty));

    // calling executor.dialect is ok, it's needed to construct the statement
    verify(executor.dialect);
    verifyNoMoreInteractions(executor);
  });

  test('same stream emits cached data when listening twice', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));

    final stream = db.select(db.users).watch();
    expect(await stream.first, isEmpty);

    clearInteractions(executor);

    await stream.first;
    verifyNever(executor.runSelect(any, any));
  });

  test('does not emit cached data when resuming and data did not change',
      () async {
    final stream = db.select(db.users).watch();
    final completer = Completer();

    final subscription = stream.listen(expectAsync1((data) {
      completer.complete();
    }));

    // The stream should emit a first event as we have a new subscription
    await completer.future;

    subscription.pause();
    await pumpEventQueue();

    // Resume and wait for a bit. The stream should not emit a second event.
    subscription.resume();
    await pumpEventQueue();
    await subscription.cancel();
  });

  test('emits new data if it changed during a paused subscription', () async {
    final stream = db.select(db.users).watch();
    final completer = Completer();

    final subscription = stream.listen(expectAsync1((data) {
      if (!completer.isCompleted) completer.complete();
    }, count: 2));

    // The stream should emit a first event as we have a new subscription
    await completer.future;

    subscription.pause();
    await pumpEventQueue();
    db.markTablesUpdated({db.users});
    await pumpEventQueue();

    // Resume and wait for a bit. The stream should update as one of its sources
    // has changed.
    subscription.resume();
    await pumpEventQueue();
    await subscription.cancel();
  });

  group('updating clears cached data', () {
    test('when an older stream is no longer listened to', () async {
      when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));
      final first = db.select(db.categories).watch();
      await first.first; // subscribe to first stream, then drop subscription

      when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([
            {
              'id': 1,
              'desc': 'd',
              'description_in_upper_case': 'D',
              'priority': 0,
            }
          ]));
      await db
          .into(db.categories)
          .insert(CategoriesCompanion.insert(description: 'd'));

      final second = db.select(db.categories).watch();
      expect(second.first, completion(isNotEmpty));
    });

    test('when an older stream is still listened to', () async {
      when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));
      final first = db.select(db.categories).watch();
      final subscription = first.listen((_) {});

      when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([
            {
              'id': 1,
              'desc': 'd',
              'description_in_upper_case': 'D',
              'priority': 0,
            }
          ]));
      await db
          .into(db.categories)
          .insert(CategoriesCompanion.insert(description: 'd'));

      final second = db.select(db.categories).watch();
      expect(second.first, completion(isNotEmpty));
      await subscription.cancel();
    });
  });

  test('every stream instance can be listened to', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));

    final first = db.select(db.users).watch();
    final second = db.select(db.users).watch();

    await first.first; // will listen to stream, then cancel
    await pumpEventQueue(times: 1); // give cancel event time to propagate

    final checkEmits = expectLater(second, emitsInOrder([[], []]));

    db.markTablesUpdated({db.users});
    await pumpEventQueue(times: 1);

    await checkEmits;
  });

  test('same stream instance can be listened to multiple times', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));

    final stream = db.select(db.users).watch();

    final firstSub = stream.take(2).listen(null); // will listen forever
    final second = await stream.first;

    expect(second, isEmpty);
    verify(executor.runSelect(any, any)).called(1);
    await firstSub.cancel();
  });

  test('streams are disposed when not listening for a while', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));

    final stream = db.select(db.users).watch();

    await stream.first; // listen to stream, then cancel
    await pumpEventQueue(); // should remove the stream from the cache
    await stream.first; // listen again
    await pumpEventQueue(times: 1);

    verify(executor.runSelect(any, any)).called(2);
  });

  test('stream emits error when loading the query throws', () {
    final exception = Exception('stub');
    when(executor.runSelect(any, any))
        .thenAnswer((_) => Future.error(exception));

    final result = db.customSelect('select 1').watch().first;
    expectLater(result, throwsA(exception));
  });

  test('database can be closed when a stream has a paused subscription',
      () async {
    // this test is more relevant than it seems - some test stream matchers
    // leave the stream in an empty state.
    final stream = db.select(db.users).watch();
    final subscription = stream.listen((_) {})..pause();

    await db.close();

    subscription.resume();
    await subscription.cancel();
  });

  group('stream keys', () {
    final keyA = StreamKey('SELECT * FROM users;', []);
    final keyB = StreamKey('SELECT * FROM users;', []);
    final keyTodos = StreamKey('SELECT * FROM todos;', []);
    final keyArgs = StreamKey('SELECT * FROM users;', ['name']);

    test('are equal for same parameters', () {
      expect(keyA, equals(keyB));
      expect(keyA.hashCode, keyB.hashCode);
    });

    test('are not equal for different queries', () {
      expect(keyA, isNot(keyTodos));
      expect(keyA.hashCode, isNot(keyTodos.hashCode));
    });

    test('are not equal for different variables', () {
      expect(keyArgs, isNot(keyA));
      expect(keyArgs.hashCode, isNot(keyA.hashCode));
    });
  });

  group("streams don't fetch", () {
    test('when no listeners were attached', () {
      db.select(db.users).watch();

      db.markTablesUpdated({db.users});

      verifyNever(executor.runSelect(any, any));
    });

    test('when the data updates after the listener has detached', () async {
      final subscription = db.select(db.users).watch().listen((_) {});

      await subscription.cancel();
      clearInteractions(executor);

      // The stream is kept open for the rest of this event iteration
      final completer = Completer.sync();
      Timer.run(completer.complete);
      await completer.future;

      db.markTablesUpdated({db.users});

      verifyNever(executor.runSelect(any, any));
    });

    test('when all listeners are paused', () async {
      when(executor.runSelect(any, any)).thenAnswer((i) => Future.value([]));
      final isPaused = Completer();

      final subscription = db.select(db.categories).watch().listen(null);
      subscription.onData((rows) {
        expect(rows, isEmpty);
        subscription.pause();

        isPaused.complete();
      });

      // Wait for the first result, then pause
      await isPaused.future;
      await pumpEventQueue();

      // Return a new row on the next select
      when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([
            {
              'id': 1,
              'desc': 'd',
              'description_in_upper_case': 'D',
              'priority': 0,
            }
          ]));
      db.markTablesUpdated([db.categories]);
      await pumpEventQueue();
      final hadData = Completer();

      subscription.onData((rows) {
        expect(rows, hasLength(1));
        hadData.complete();
      });

      subscription.resume();
      await hadData.future;

      await subscription.cancel();
      verify(executor.runSelect(any, any)).called(2);
    });
  });

  // note: There's a trigger on config inserts that updates with_defaults
  test('updates streams for updates caused by triggers', () async {
    final db = CustomTablesDb(executor);
    db.select(db.withDefaults).watch().listen((_) {});

    db.notifyUpdates({const TableUpdate('config', kind: UpdateKind.insert)});
    await pumpEventQueue(times: 1);

    verify(executor.runSelect(any, any)).called(2);
  });

  test('limits trigger propagation to the target type of trigger', () async {
    final db = CustomTablesDb(executor);
    db.select(db.withDefaults).watch().listen((_) {});

    db.notifyUpdates({const TableUpdate('config', kind: UpdateKind.delete)});
    await pumpEventQueue(times: 1);

    verify(executor.runSelect(any, any)).called(1);
  });

  group('listen for table updates', () {
    test('any', () async {
      var counter = 0;
      db.tableUpdates().listen((event) => counter++);

      db.markTablesUpdated({db.todosTable});
      await pumpEventQueue(times: 1);
      expect(counter, 1);

      db.markTablesUpdated({db.users});
      await pumpEventQueue(times: 1);
      expect(counter, 2);
    });

    test('stream is async', () {
      var counter = 0;
      db.tableUpdates().listen((event) => counter++);

      db.markTablesUpdated({});
      // no wait here, the counter should not be updated yet.
      expect(counter, 0);
    });

    test('specific table', () async {
      var counter = 0;
      db
          .tableUpdates(TableUpdateQuery.onTable(db.users))
          .listen((event) => counter++);

      db.markTablesUpdated({db.todosTable});
      await pumpEventQueue(times: 1);
      expect(counter, 0);

      db.markTablesUpdated({db.users});
      await pumpEventQueue(times: 1);
      expect(counter, 1);

      db.markTablesUpdated({db.categories});
      await pumpEventQueue(times: 1);
      expect(counter, 1);
    });

    test('specific table and update kind', () async {
      var counter = 0;
      db
          .tableUpdates(TableUpdateQuery.onTable(db.users,
              limitUpdateKind: UpdateKind.update))
          .listen((event) => counter++);

      db.markTablesUpdated({db.todosTable});
      await pumpEventQueue(times: 1);
      expect(counter, 0);

      db.notifyUpdates(
          {TableUpdate.onTable(db.users, kind: UpdateKind.update)});
      await pumpEventQueue(times: 1);
      expect(counter, 1);

      db.notifyUpdates(
          {TableUpdate.onTable(db.users, kind: UpdateKind.delete)});
      await pumpEventQueue(times: 1);
      expect(counter, 1);
    });

    test('filters relevant updates from single event', () async {
      final stream = db.tableUpdates(TableUpdateQuery.onTable(db.users));
      expect(stream, emits({TableUpdate.onTable(db.users)}));

      db.notifyUpdates({
        TableUpdate.onTable(db.todosTable),
        TableUpdate.onTable(db.users),
      });
    });
  });

  test('stream queries are broadcasts', () {
    expect(db.customSelect('SELECT 1').watch().isBroadcast, isTrue);
    expect(db.customSelect('SELECT 1').watchSingle().isBroadcast, isTrue);
  });
}
