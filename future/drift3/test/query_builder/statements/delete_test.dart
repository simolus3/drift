import 'package:drift3/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils.dart';
import '../../test_utils/mocks.dart';
import '../../test_utils/test_query_store.dart';

void main() {
  late TodoDb db;
  late MockSession session;
  late TestStreamQueryStore streamQueries;

  setUp(() async {
    session = MockSession();
    streamQueries = TestStreamQueryStore();
    db = TodoDb(createConnection(session, streams: streamQueries));

    // Don't collect CREATE TABLE statements in mock to make debugging easier.
    await db.initialize();
    clearInteractions(session);
  });

  group('Generates DELETE statements', () {
    test('without any constraints', () async {
      await db.delete(db.users).go();

      verify(session.executeSql('DELETE FROM "users";', isEmpty));
    });

    test('for complex components', () async {
      await (db.delete(
        db.users,
      )..where((u) => u.isAwesome.not() | u.id.isLessThanValue(100))).go();

      verify(
        session.executeSql(
          'DELETE FROM "users" WHERE NOT "is_awesome" OR "id" < ?1;',
          const [100],
        ),
      );
    });

    test('to delete an entity via a dataclasss', () async {
      await db
          .delete(db.sharedTodos)
          .delete(const SharedTodo(todo: 3, user: 2));

      verify(
        session.executeSql(
          'DELETE FROM "shared_todos" WHERE "todo" = ?1 AND "user" = ?2;',
          const [3, 2],
        ),
      );
    });

    group('RETURNING', () {
      test('for one row', () async {
        when(session.execute(any)).thenAnswer((_) {
          return Future.value(
            queryResult([
              {
                'id': 10,
                'title': null,
                'content': 'Content',
                'target_date': null,
                'category': null,
                'status': null,
              },
            ], affectedRows: 1),
          );
        });

        final returnedValue = await db
            .delete(db.todosTable)
            .deleteReturning(const TodosTableCompanion(id: Value(RowId(10))));

        verify(
          session.executeSql(
            'DELETE FROM "todos" WHERE "id" = ?1 RETURNING "id","title","content","target_date","category","status";',
            [10],
          ),
        );
        expect(streamQueries.recordedUpdates, {
          TableUpdate.onTable(db.todosTable, kind: UpdateKind.delete),
        });
        expect(
          returnedValue,
          const TodoEntry(id: RowId(10), content: 'Content'),
        );
      });

      test('for multiple rows', () async {
        when(session.execute(any)).thenAnswer((_) {
          return Future.value(queryResult([], affectedRows: 0));
        });
        final rows = await db.delete(db.users).goAndReturn();

        expect(rows, isEmpty);
        verify(
          session.executeSql(
            'DELETE FROM "users" RETURNING "id","name","is_awesome","profile_picture","creation_time";',
            [],
          ),
        );
        expect(streamQueries.recordedUpdates, isEmpty);
      });

      test('only', () async {
        when(session.execute(any)).thenAnswer((_) {
          return Future.value(
            queryResult(const [
              {'name': 'foo', 'id': 1},
              {'name': 'bar', 'id': 2},
            ], affectedRows: 2),
          );
        });

        final rows = await db.delete(db.users).goAndReturnOnly([
          db.users.name,
          db.users.id,
        ]);

        expect(rows.map((s) => s.raw), const [
          ["foo", 1],
          ["bar", 2],
        ]);
        verify(
          session.executeSql('DELETE FROM "users" RETURNING "name","id";', []),
        );
        expect(streamQueries.recordedUpdates, {
          TableUpdate.onTable(db.users, kind: UpdateKind.delete),
        });
      });
    });
  });

  group('executes DELETE statements', () {
    test('and reports the correct amount of affected rows', () async {
      when(session.execute(any)).thenAnswer((_) {
        return Future.value(queryResult(null, affectedRows: 12));
      });

      expect(await db.delete(db.users).go(), 12);
    });
  });

  group('Table updates for delete statements', () {
    test('are issued when data was changed', () async {
      when(session.execute(any)).thenAnswer((_) {
        return Future.value(queryResult(null, affectedRows: 3));
      });

      await db.delete(db.users).go();

      expect(streamQueries.recordedUpdates, {
        const TableUpdate('users', kind: UpdateKind.delete),
      });
    });

    test('are not issued when no data was changed', () async {
      when(session.execute(any)).thenAnswer((_) {
        return Future.value(queryResult(null, affectedRows: 0));
      });

      await db.delete(db.users).go();

      expect(streamQueries.recordedUpdates, isEmpty);
    });
  });
}
