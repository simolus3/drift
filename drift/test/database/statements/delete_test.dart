import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;
  late MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streamQueries);
    db = TodoDb.connect(connection);
  });

  group('Generates DELETE statements', () {
    test('without any constraints', () async {
      await db.delete(db.users).go();

      verify(executor.runDelete('DELETE FROM "users";', argThat(isEmpty)));
    });

    test('for complex components', () async {
      await (db.delete(db.users)
            ..where((u) => u.isAwesome.not() | u.id.isSmallerThanValue(100)))
          .go();

      verify(executor.runDelete(
          'DELETE FROM "users" WHERE NOT "is_awesome" OR "id" < ?;',
          const [100]));
    });

    test('to delete an entity via a dataclasss', () async {
      await db
          .delete(db.sharedTodos)
          .delete(const SharedTodo(todo: 3, user: 2));

      verify(executor.runDelete(
        'DELETE FROM "shared_todos" WHERE "todo" = ? AND "user" = ?;',
        const [3, 2],
      ));
    });

    group('RETURNING', () {
      test('for one row', () async {
        when(executor.runSelect(any, any)).thenAnswer((_) {
          return Future.value([
            {'id': 10, 'content': 'Content'}
          ]);
        });

        final returnedValue = await db
            .delete(db.todosTable)
            .deleteReturning(const TodosTableCompanion(id: Value(10)));

        verify(executor.runSelect(
            'DELETE FROM "todos" WHERE "id" = ? RETURNING *;', [10]));
        verify(streamQueries.handleTableUpdates(
            {TableUpdate.onTable(db.todosTable, kind: UpdateKind.delete)}));
        expect(returnedValue, const TodoEntry(id: 10, content: 'Content'));
      });

      test('for multiple rows', () async {
        final rows = await db.delete(db.users).goAndReturn();

        expect(rows, isEmpty);
        verify(executor.runSelect('DELETE FROM "users" RETURNING *;', []));
        verifyNever(streamQueries.handleTableUpdates(any));
      });
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

      verify(streamQueries.handleTableUpdates(
          {const TableUpdate('users', kind: UpdateKind.delete)}));
    });

    test('are not issued when no data was changed', () async {
      when(executor.runDelete(any, any)).thenAnswer((_) => Future.value(0));

      await db.delete(db.users).go();

      verifyNever(streamQueries.handleTableUpdates(any));
    });
  });

  group('delete on table instances', () {
    test('delete()', () async {
      await db.users.delete().go();

      verify(executor.runDelete('DELETE FROM "users";', const []));
    });

    test('deleteOne()', () async {
      await db.users.deleteOne(const UsersCompanion(id: Value(3)));

      verify(
          executor.runDelete('DELETE FROM "users" WHERE "id" = ?;', const [3]));
    });

    test('deleteWhere', () async {
      await db.users.deleteWhere((tbl) => tbl.id.isSmallerThanValue(3));

      verify(
          executor.runDelete('DELETE FROM "users" WHERE "id" < ?;', const [3]));
    });
  });
}
