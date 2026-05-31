import 'dart:typed_data';

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils.dart';
import '../../test_utils/mocks.dart';
import '../../test_utils/test_query_store.dart';

void main() {
  late TodoDb db;
  late MockSession executor;
  late TestStreamQueryStore streamQueries;

  setUp(() async {
    executor = MockSession();
    streamQueries = TestStreamQueryStore();

    final connection = createConnection(executor, streams: streamQueries);
    db = TodoDb(connection);

    await db.initialize();
    clearInteractions(executor);
  });

  group('generates update statements', () {
    test('for entire table', () async {
      await db
          .update(db.todosTable)
          .write(
            const TodosTableCompanion(
              title: Value('Updated title'),
              category: Value(RowId(3)),
            ),
          );

      verify(
        executor.executeSql(
          'UPDATE "todos" SET "title" = ?1,"category" = ?2;',
          ['Updated title', 3],
        ),
      );

      final stmt = db.update(db.users);
      final compiled = db.dialect.compile(stmt);
      expect(compiled.expectedWrites, [
        TableUpdate.onTable(db.users, kind: UpdateKind.update),
      ]);
    });

    test('with a WHERE clause', () async {
      await (db.update(db.todosTable)..where((t) => t.id.isLessThanValue(50)))
          .write(const TodosTableCompanion(title: Value('Changed title')));

      verify(
        executor.executeSql(
          'UPDATE "todos" SET "title" = ?1 WHERE "id" < ?2;',
          ['Changed title', 50],
        ),
      );
    });

    test('with escaped column names', () async {
      await db
          .update(db.pureDefaults)
          .write(PureDefaultsCompanion(txt: Value(MyCustomObject('foo'))));

      verify(
        executor.executeSql('UPDATE "pure_defaults" SET "insert" = ?1;', [
          'foo',
        ]),
      );
    });
  });

  group('generates replace statements', () {
    test('regular', () async {
      await db
          .update(db.todosTable)
          .replace(
            const TodoEntry(
              id: RowId(3),
              title: 'Title',
              content: 'Updated content',
              status: TodoStatus.workInProgress,
              // category and targetDate are null
            ),
          );

      verify(
        executor.executeSql(
          'UPDATE "todos" SET "title" = ?1,"content" = ?2,'
          '"target_date" = ?3,"category" = ?3,"status" = ?4 WHERE "id" = ?5;',
          const ['Title', 'Updated content', null, 'workInProgress', 3],
        ),
      );
    });

    test('applies default values', () async {
      await db
          .update(db.users)
          .replace(
            UsersCompanion(
              id: const Value(RowId(3)),
              name: const Value('Hummingbird'),
              profilePicture: Value(Uint8List(0)),
            ),
          );

      verify(
        executor.executeSql(
          'UPDATE "users" SET "name" = ?1,"profile_picture" = ?2,'
          '"is_awesome" = 1,"creation_time" = CURRENT_TIMESTAMP '
          'WHERE "id" = ?3;',
          ['Hummingbird', Uint8List(0), 3],
        ),
      );
    });
  });

  group('Table updates for update statements', () {
    test('are issued when data was changed', () async {
      when(
        executor.execute(any),
      ).thenAnswer((_) async => QueryResult(resultSet: null, affectedRows: 3));

      await db
          .update(db.todosTable)
          .write(const TodosTableCompanion(content: Value('Updated content')));

      expect(streamQueries.recordedUpdates, {
        TableUpdate.onTable(db.todosTable, kind: UpdateKind.update),
      });
    });

    test('are not issued when no data was changed', () async {
      when(
        executor.execute(any),
      ).thenAnswer((_) async => QueryResult(resultSet: null, affectedRows: 0));

      await db.update(db.todosTable).write(const TodosTableCompanion());

      expect(streamQueries.recordedUpdates, isEmpty);
    });
  });

  test('can update with custom companions', () async {
    await db
        .update(db.todosTable)
        .replace(
          TodosTableCompanion.custom(
            id: const Variable(4),
            content: db.todosTable.content.dartCast(),
            targetDate: db.todosTable.targetDate + const Duration(days: 1),
          ),
        );

    verify(
      executor.executeSql(
        '''UPDATE "todos" SET "content" = "content","target_date" = datetime("target_date",'86400.0 seconds') WHERE "id" = ?1;''',
        [4],
      ),
    );
  });

  group('custom updates', () {
    test('execute the correct sql', () async {
      await db.customUpdate('DELETE FROM "users"');

      verify(executor.executeSql('DELETE FROM "users"'));
    });

    test('map the variables correctly', () async {
      await db.customUpdate(
        'DELETE FROM "users" WHERE "name" = ? AND "birthdate" < ?',
        variables: [
          db.mapValue(BuiltinDriftType.text, 'Name'),
          db.mapValue(BuiltinDriftType.dateTime, DateTime.utc(2025, 5, 10, 10)),
        ],
      );

      verify(
        executor.executeSql(
          'DELETE FROM "users" WHERE "name" = ? AND "birthdate" < ?',
          ['Name', '2025-05-10T10:00:00.000Z'],
        ),
      );
    });

    test('returns information from executor', () async {
      when(
        executor.execute(any),
      ).thenAnswer((_) async => QueryResult(resultSet: null, affectedRows: 10));

      expect(await db.customUpdate(''), 10);
    });

    test('informs about updated tables', () async {
      await db.customUpdate('', updates: {db.users, db.todosTable});

      expect(streamQueries.recordedUpdates, {
        const TableUpdate('users', kind: UpdateKind.update),
        const TableUpdate('todos', kind: UpdateKind.update),
      });
    });
  });

  group('RETURNING', () {
    test('for one row', () async {
      when(executor.execute(any)).thenAnswer((_) {
        return Future.value(
          queryResult([
            {
              'id': 3,
              'desc': 'test',
              'priority': 0,
              'description_in_upper_case': 'TEST',
            },
          ], affectedRows: 1),
        );
      });

      final rows = await db
          .update(db.categories)
          .writeReturning(
            const CategoriesCompanion(description: Value('test')),
          );

      verify(
        executor.executeSql(
          'UPDATE "categories" SET "desc" = ?1 RETURNING '
          '"id","desc","priority","description_in_upper_case";',
          ['test'],
        ),
      );
      expect(streamQueries.recordedUpdates, {
        TableUpdate.onTable(db.categories, kind: UpdateKind.update),
      });

      expect(rows, const [
        Category(
          id: RowId(3),
          description: 'test',
          priority: CategoryPriority.low,
          descriptionInUpperCase: 'TEST',
        ),
      ]);
    });

    test('only', () async {
      when(executor.execute(any)).thenAnswer((_) {
        return Future.value(
          queryResult([
            {'description_in_upper_case': 'TEST'},
          ], affectedRows: 1),
        );
      });

      final rows = await db.update(db.categories).writeReturningOnly(
        const CategoriesCompanion(priority: Value(CategoryPriority.high)),
        [db.categories.descriptionInUpperCase],
      );

      verify(
        executor.executeSql(
          'UPDATE "categories" SET "priority" = ?1 RETURNING '
          '"description_in_upper_case";',
          [2],
        ),
      );
      expect(streamQueries.recordedUpdates, {
        TableUpdate.onTable(db.categories, kind: UpdateKind.update),
      });

      expect(rows.map((s) => s.raw), const [
        ['TEST'],
      ]);
    });
  });

  test('can use empty companion for update', () async {
    expect(
      await db
          .update(db.categories)
          .writeReturning(const CategoriesCompanion()),
      isEmpty,
    );

    verifyNever(executor.execute(any));
  });
}
