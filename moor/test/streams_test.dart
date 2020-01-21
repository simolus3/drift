import 'dart:async';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;
  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('streams fetch when the first listener attaches', () {
    final stream = db.select(db.users).watch();

    verifyNever(executor.runSelect(any, any));

    stream.listen((_) {});

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

  group('updating clears cached data', () {
    test('when an older stream is no longer listened to', () async {
      when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));
      final first = db.select(db.categories).watch();
      await first.first; // subscribe to first stream, then drop subscription

      when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([
            {'id': 1, 'description': 'd'}
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
            {'id': 1, 'description': 'd'}
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

    final result = db.customSelectQuery('select 1').watch().first;
    expectLater(result, throwsA(exception));
  });

  group('stream keys', () {
    final keyA = StreamKey('SELECT * FROM users;', [], User);
    final keyB = StreamKey('SELECT * FROM users;', [], User);
    final keyCustom = StreamKey('SELECT * FROM users;', [], QueryRow);
    final keyCustomTodos = StreamKey('SELECT * FROM todos;', [], QueryRow);
    final keyArgs = StreamKey('SELECT * FROM users;', ['name'], User);

    test('are equal for same parameters', () {
      expect(keyA, equals(keyB));
      expect(keyA.hashCode, keyB.hashCode);
    });

    test('are not equal for different queries', () {
      expect(keyCustomTodos, isNot(keyCustom));
      expect(keyCustomTodos.hashCode, isNot(keyCustom.hashCode));
    });

    test('are not equal for different variables', () {
      expect(keyArgs, isNot(keyA));
      expect(keyArgs.hashCode, isNot(keyA.hashCode));
    });

    test('are not equal for different types', () {
      expect(keyCustom, isNot(keyA));
      expect(keyCustom.hashCode, isNot(keyA.hashCode));
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
      clearInteractions(executor);

      await subscription.cancel();

      // The stream is kept open for the rest of this event iteration
      final completer = Completer.sync();
      Timer.run(completer.complete);
      await completer.future;

      db.markTablesUpdated({db.users});

      verifyNever(executor.runSelect(any, any));
    });
  });
}
