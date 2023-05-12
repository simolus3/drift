import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;
  late MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();

    db = TodoDb(createConnection(executor, streamQueries));
  });

  test('runs generated statements', () async {
    await db.batch((b) {
      b.insertAll(
        db.todosTable,
        [
          TodosTableCompanion.insert(content: 'first'),
          TodosTableCompanion.insert(content: 'second'),
        ],
      );

      b.update(db.users, const UsersCompanion(name: Value('new name')));
      b.update(
        db.users,
        const UsersCompanion(name: Value('Another')),
        where: (Users row) => row.name.equals('old'),
      );

      b.replaceAll(db.categories, const [
        CategoriesCompanion(id: Value(1), description: Value('new1')),
        CategoriesCompanion(id: Value(2), description: Value('new2')),
      ]);

      b.deleteWhere<$CategoriesTable, Category>(
          db.categories, (tbl) => tbl.id.equals(1));
      b.deleteAll(db.categories);
      b.delete(db.todosTable, const TodosTableCompanion(id: Value(3)));

      b.update(db.users, const UsersCompanion(name: Value('new name 2')));

      b.customStatement('some custom statement', [4]);
    });

    final transaction = executor.transactions;
    verify(
      transaction.runBatched(
        BatchedStatements(
          [
            'INSERT INTO "todos" ("content") VALUES (?)',
            'UPDATE "users" SET "name" = ?;',
            'UPDATE "users" SET "name" = ? WHERE "name" = ?;',
            'UPDATE "categories" SET "desc" = ?, "priority" = 0 WHERE "id" = ?;',
            'DELETE FROM "categories" WHERE "id" = ?;',
            'DELETE FROM "categories";',
            'DELETE FROM "todos" WHERE "id" = ?;',
            'some custom statement',
          ],
          [
            ArgumentsForBatchedStatement(0, ['first']),
            ArgumentsForBatchedStatement(0, ['second']),
            ArgumentsForBatchedStatement(1, ['new name']),
            ArgumentsForBatchedStatement(2, ['Another', 'old']),
            ArgumentsForBatchedStatement(3, ['new1', 1]),
            ArgumentsForBatchedStatement(3, ['new2', 2]),
            ArgumentsForBatchedStatement(4, [1]),
            ArgumentsForBatchedStatement(5, []),
            ArgumentsForBatchedStatement(6, [3]),
            ArgumentsForBatchedStatement(1, ['new name 2']),
            ArgumentsForBatchedStatement(7, [4]),
          ],
        ),
      ),
    );
  });

  test('custom statement can update queries', () async {
    final update = TableUpdate.onTable(db.users);

    await db.batch((batch) {
      batch.customStatement('SELECT 1', [], {update});
    });

    verify(streamQueries.handleTableUpdates(argThat(contains(update))));
  });

  test('supports inserts with upsert clause', () async {
    await db.batch((batch) {
      batch.insert(
        db.categories,
        CategoriesCompanion.insert(description: 'description'),
        onConflict: DoUpdate((old) {
          return const CategoriesCompanion(id: Value(42));
        }),
      );
    });

    verify(executor.transactions.runBatched(BatchedStatements(
      [
        ('INSERT INTO "categories" ("desc") VALUES (?) '
            'ON CONFLICT("id") DO UPDATE SET "id" = ?')
      ],
      [
        ArgumentsForBatchedStatement(0, ['description', 42])
      ],
    )));
  });

  test('insertAllOnConflictUpdate', () async {
    final entries = [
      CategoriesCompanion.insert(description: 'first'),
      CategoriesCompanion.insert(description: 'second'),
    ];

    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.categories, entries);
    });

    verify(executor.transactions.runBatched(BatchedStatements(
      [
        ('INSERT INTO "categories" ("desc") VALUES (?) '
            'ON CONFLICT("id") DO UPDATE SET "desc" = ?')
      ],
      [
        ArgumentsForBatchedStatement(0, ['first', 'first']),
        ArgumentsForBatchedStatement(0, ['second', 'second']),
      ],
    )));
  });

  test('insert with where clause and excluded table', () async {
    // https://github.com/simolus3/drift/issues/1781
    final entries = [
      CategoriesCompanion.insert(description: 'first'),
      CategoriesCompanion.insert(description: 'second'),
    ];

    await db.batch((batch) {
      batch.insertAll<Categories, Category>(
        db.categories,
        entries,
        onConflict: DoUpdate.withExcluded(
          (old, excluded) => CategoriesCompanion.custom(
            description: old.description.dartCast(),
            priority: excluded.priority.dartCast(),
          ),
          where: (old, excluded) =>
              old.id.dartCast<int>().isBiggerOrEqual(excluded.id.dartCast()),
        ),
      );
    });

    verify(executor.transactions.runBatched(BatchedStatements(
      [
        ('INSERT INTO "categories" ("desc") VALUES (?) ON CONFLICT("id") '
            'DO UPDATE SET "desc" = "categories"."desc", '
            '"priority" = "excluded"."priority" WHERE "categories"."id" >= "excluded"."id"')
      ],
      [
        ArgumentsForBatchedStatement(0, ['first']),
        ArgumentsForBatchedStatement(0, ['second']),
      ],
    )));
  });

  test('can re-use an outer transaction', () async {
    await db.transaction(() async {
      await db.batch((b) {});
    });

    verifyNever(executor.runBatched(any));
    verify(executor.transactions.runBatched(any));
  }, onPlatform: const {
    'js': [Skip('Blocked by https://github.com/dart-lang/mockito/issues/198')]
  });

  test('supports async batch functions', () async {
    await db.batch((batch) async {
      batch.insert(
          db.categories, CategoriesCompanion.insert(description: 'first'));

      await Future<void>.delayed(Duration.zero);

      batch.insert(
          db.categories, CategoriesCompanion.insert(description: 'second'));
    });

    verify(executor.transactions.runBatched(BatchedStatements(
      ['INSERT INTO "categories" ("desc") VALUES (?)'],
      [
        ArgumentsForBatchedStatement(0, ['first']),
        ArgumentsForBatchedStatement(0, ['second']),
      ],
    )));
  });

  test('updates stream queries', () async {
    await db.batch((b) {
      b.insert(db.todosTable, const TodoEntry(id: 3, content: 'content'));

      b.update(db.users, const UsersCompanion(name: Value('new user name')));
      b.replace(
        db.todosTable,
        const TodosTableCompanion(id: Value(3), content: Value('new')),
      );

      b.deleteWhere(db.todosTable, (TodosTable row) => row.id.equals(3));
      b.delete(db.todosTable, const TodosTableCompanion(id: Value(3)));
    });

    verify(
      streamQueries.handleTableUpdates({
        const TableUpdate('todos', kind: UpdateKind.insert),
        const TableUpdate('users', kind: UpdateKind.update),
        const TableUpdate('todos', kind: UpdateKind.update),
        const TableUpdate('todos', kind: UpdateKind.delete),
      }),
    );
  });

  test('does not start a new transaction when running in a transaction',
      () async {
    await db.transaction(() async {
      await db.batch((batch) {});
      await db.batch((batch) {});
    });

    verify(executor.beginTransaction()).called(1);
  });

  test('starts a new transaction when not running in a transaction', () async {
    await db.batch((batch) {});

    verify(executor.beginTransaction()).called(1);
  });
}
