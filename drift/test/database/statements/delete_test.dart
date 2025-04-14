import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockSession executor;
  late MockStreamQueries streamQueries;

  setUp(() {
    executor = MockSession();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streams: streamQueries);
    db = TodoDb(connection);
  });

  group('Generates DELETE statements', () {
    test('without any constraints', () async {
      final stmt = db.delete(db.users);

      final compiled = db.dialect.compile(stmt);
      expect(compiled.possibleUpdates,
          [TableUpdate.onTable(db.users, kind: UpdateKind.delete)]);

      await stmt.go();
      verify(executor.executeSql('DELETE FROM "users";'));
    });

    test('for complex components', () async {
      await db
          .delete(db.users)
          .where((u) => u.isAwesome.not() | u.id.isLessThanValue(100))
          .go();

      verify(executor.executeSql(
          'DELETE FROM "users" WHERE NOT "is_awesome" OR "id" < ?1;',
          const [100]));
    });

    test('to delete an entity via a dataclasss', () async {
      await db
          .delete(db.sharedTodos)
          .delete(const SharedTodo(todo: 3, user: 2));

      verify(executor.executeSql(
        'DELETE FROM "shared_todos" WHERE "todo" = ?1 AND "user" = ?2;',
        const [3, 2],
      ));
    });

    group('RETURNING', () {
      test('for one row', () async {
        when(executor.execute(any)).thenAnswer((_) async {
          return queryResult(affectedRows: 1, [
            {
              for (final column in db.todosTable.columns)
                column.name: switch (column.name) {
                  'id' => 10,
                  'content' => 'Content',
                  _ => null,
                },
            },
          ]);
        });

        final returnedValue = await db
            .delete(db.todosTable)
            .deleteReturning(const TodosTableCompanion(id: Value(RowId(10))));

        verify(executor.executeSql(
            'DELETE FROM "todos" WHERE "id" = ?1 RETURNING *;', [10]));
        verify(streamQueries.handleTableUpdates(
            {TableUpdate.onTable(db.todosTable, kind: UpdateKind.delete)}));
        expect(
            returnedValue, const TodoEntry(id: RowId(10), content: 'Content'));
      });

      test('for multiple rows', () async {
        final rows = await db.delete(db.users).goAndReturn();

        expect(rows, isEmpty);
        verify(executor.executeSql('DELETE FROM "users" RETURNING *;'));
        verifyNever(streamQueries.handleTableUpdates(any));
      });
    });
  });

  group('executes DELETE statements', () {
    test('and reports the correct amount of affected rows', () async {
      when(executor.execute(any))
          .thenAnswer((_) async => queryResult(const [], affectedRows: 12));

      expect(await db.delete(db.users).go(), 12);
    });
  });

  group('Table updates for delete statements', () {
    test('are issued when data was changed', () async {
      when(executor.execute(any))
          .thenAnswer((_) async => queryResult(const [], affectedRows: 12));

      await db.delete(db.users).go();

      verify(streamQueries.handleTableUpdates(
          {const TableUpdate('users', kind: UpdateKind.delete)}));
    });

    test('are not issued when no data was changed', () async {
      when(executor.execute(any))
          .thenAnswer((_) async => queryResult(const [], affectedRows: 0));

      await db.delete(db.users).go();

      verifyNever(streamQueries.handleTableUpdates(any));
    });
  });
}
