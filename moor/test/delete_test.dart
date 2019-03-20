import 'dart:async';

import 'package:moor/moor.dart';
import 'package:test_api/test_api.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;
  MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();
    db = TodoDb(executor)..streamQueries = streamQueries;
  });

  group('Generates DELETE statements', () {
    test('without any constraints', () async {
      await db.delete(db.users).go();

      verify(executor.runDelete('DELETE FROM users;', argThat(isEmpty)));
    });

    test('for complex components', () async {
      await (db.delete(db.users)
            ..where((u) => or(not(u.isAwesome), u.id.isSmallerThanValue(100))))
          .go();

      verify(executor.runDelete(
          'DELETE FROM users WHERE (NOT (is_awesome = 1)) OR (id < ?);',
          [100]));
    });

    test('to delete an entity via a dataclasss', () async {
      await db.delete(db.sharedTodos).delete(SharedTodo(todo: 3, user: 2));

      verify(executor.runDelete(
          'DELETE FROM shared_todos WHERE (todo = ?) AND (user = ?);', [3, 2]));
    });
  });

  group('executes DELETE statements', () {
    test('and reports the correct amount of affected rows', () async {
      when(executor.runDelete(any, any)).thenAnswer((_) async => 12);

      expect(await db.delete(db.users).go(), 12);
    });
  });

  group('Table updates for delete statements', () {
    test('are issued when data was changed', () async {
      when(executor.runDelete(any, any)).thenAnswer((_) => Future.value(3));

      await db.delete(db.users).go();

      verify(streamQueries.handleTableUpdates({db.users}));
    });

    test('are not issued when no data was changed', () async {
      when(executor.runDelete(any, any)).thenAnswer((_) => Future.value(0));

      await db.delete(db.users).go();

      verifyNever(streamQueries.handleTableUpdates(any));
    });
  });
}
