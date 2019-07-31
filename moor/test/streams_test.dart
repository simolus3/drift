import 'dart:async';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:test_api/test_api.dart';

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

    db.markTablesUpdated({second});
    await pumpEventQueue(times: 1);

    verify(executor.runSelect(any, any)).called(2);
  });

  test('streams emit cached data when a new listener attaches', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));

    final first = (db.select(db.users).watch());
    expect(first, emits(isEmpty));

    clearInteractions(executor);

    final second = (db.select(db.users).watch());
    expect(second, emits(isEmpty));

    await pumpEventQueue(times: 1);
    // calling executor.dialect is ok, it's needed to construct the statement
    verify(executor.dialect);
    verifyNoMoreInteractions(executor);
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

  test('streams can be reused after a listener detaches', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));

    final stream = db.select(db.users).watch();

    await stream.first; // listen to stream, then cancel
    await stream.first; // listen again

    verify(executor.runSelect(any, any)).called(1); // cached, only called once
  });

  test('streams are disposed when not listening for a while', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));

    final stream = db.select(db.users).watch();

    await stream.first; // listen to stream, then cancel
    await pumpEventQueue(); // should remove the stream from the cache
    await stream.first; // listen again

    verify(executor.runSelect(any, any)).called(2);
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

    test('when the data updates after the listener has detached', () {
      final subscription = db.select(db.users).watch().listen((_) {});
      clearInteractions(executor);

      subscription.cancel();
      db.markTablesUpdated({db.users});

      verifyNever(executor.runSelect(any, any));
    });
  });
}
