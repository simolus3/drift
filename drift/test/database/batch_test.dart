import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockSession executor;
  late MockStreamQueries streamQueries;

  setUp(() {
    executor = MockSession();
    streamQueries = MockStreamQueries();

    db = TodoDb(createConnection(executor, streams: streamQueries));
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
        CategoriesCompanion(id: Value(RowId(1)), description: Value('new1')),
        CategoriesCompanion(id: Value(RowId(2)), description: Value('new2')),
      ]);

      b.deleteWhere<Category, $CategoriesTable>(
          db.categories, (tbl) => tbl.id.equals(1));
      b.deleteAll(db.categories);
      b.delete(db.todosTable, const TodosTableCompanion(id: Value(RowId(3))));

      b.update(db.users, const UsersCompanion(name: Value('new name 2')));

      b.customStatement('some custom statement', [(BuiltinDriftType.int, 4)]);
    });

    final transaction = executor.transactions;
    final batch = verify(transaction.executeBatch(captureAny)).captured.single
        as StatementBatch;

    expect(batch.sql, [
      'INSERT INTO "todos" ("content") VALUES (?1)',
      'UPDATE "users" SET "name" = ?1;',
      'UPDATE "users" SET "name" = ?1 WHERE "name" = ?2;',
      'UPDATE "categories" SET "desc" = ?1,"priority" = 0 WHERE "id" = ?2;',
      'DELETE FROM "categories" WHERE "id" = ?1;',
      'DELETE FROM "categories";',
      'DELETE FROM "todos" WHERE "id" = ?1;',
      'some custom statement',
    ]);

    expect(batch.statements, [
      isStatementInBatch(0, ['first']),
      isStatementInBatch(0, ['second']),
      isStatementInBatch(1, ['new name']),
      isStatementInBatch(2, ['Another', 'old']),
      isStatementInBatch(3, ['new1', 1]),
      isStatementInBatch(3, ['new2', 2]),
      isStatementInBatch(4, [1]),
      isStatementInBatch(5, []),
      isStatementInBatch(6, [3]),
      isStatementInBatch(1, ['new name 2']),
      isStatementInBatch(7, [4]),
    ]);
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
      batch.insert<Category, $CategoriesTable>(
        db.categories,
        CategoriesCompanion.insert(description: 'description'),
        onConflict: DoUpdate((old) {
          return const CategoriesCompanion(id: Value(RowId(42)));
        }),
      );
    });

    final batch = verify(executor.transactions.executeBatch(captureAny))
        .captured
        .single as StatementBatch;
    expect(batch.sql, [
      ('INSERT INTO "categories" ("desc") VALUES (?1) '
          'ON CONFLICT("id") DO UPDATE SET "id" = ?2')
    ]);
    expect(batch.statements, [
      isStatementInBatch(0, ['description', 42])
    ]);
  });

  test('insertAllOnConflictUpdate', () async {
    final entries = [
      CategoriesCompanion.insert(description: 'first'),
      CategoriesCompanion.insert(description: 'second'),
    ];

    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.categories, entries);
    });

    final batch = verify(executor.transactions.executeBatch(captureAny))
        .captured
        .single as StatementBatch;
    expect(batch.sql, [
      ('INSERT INTO "categories" ("desc") VALUES (?1) '
          'ON CONFLICT("id") DO UPDATE SET "desc" = ?1')
    ]);
    expect(batch.statements, [
      isStatementInBatch(0, ['first']),
      isStatementInBatch(0, ['second']),
    ]);
  });

  test('insert with where clause and excluded table', () async {
    // https://github.com/simolus3/drift/issues/1781
    final entries = [
      CategoriesCompanion.insert(description: 'first'),
      CategoriesCompanion.insert(description: 'second'),
    ];

    await db.batch((batch) {
      batch.insertAll<Category, $CategoriesTable>(
        db.categories,
        entries,
        onConflict: DoUpdate.withExcluded(
          (old, excluded) => CategoriesCompanion.custom(
            description: old.description.dartCast(),
            priority: excluded.priority.dartCast(),
          ),
          where: (old, excluded) =>
              old.id.dartCast<int>().isGreaterOrEqual(excluded.id.dartCast()),
        ),
      );
    });

    final batch = verify(executor.transactions.executeBatch(captureAny))
        .captured
        .single as StatementBatch;
    expect(batch.sql, [
      ('INSERT INTO "categories" ("desc") VALUES (?1) ON CONFLICT("id") '
          'DO UPDATE SET "desc" = "categories"."desc",'
          '"priority" = "excluded"."priority" WHERE "categories"."id" >= "excluded"."id"')
    ]);
    expect(batch.statements, [
      isStatementInBatch(0, ['first']),
      isStatementInBatch(0, ['second']),
    ]);
  });

  test('supports async batch functions', () async {
    await db.batch((batch) async {
      batch.insert(
          db.categories, CategoriesCompanion.insert(description: 'first'));

      await Future<void>.delayed(Duration.zero);

      batch.insert(
          db.categories, CategoriesCompanion.insert(description: 'second'));
    });

    final batch = verify(executor.transactions.executeBatch(captureAny))
        .captured
        .single as StatementBatch;
    expect(batch.sql, ['INSERT INTO "categories" ("desc") VALUES (?1)']);
    expect(batch.statements, [
      isStatementInBatch(0, ['first']),
      isStatementInBatch(0, ['second']),
    ]);
  });

  test('updates stream queries', () async {
    await db.batch((b) {
      b.insert(
          db.todosTable, const TodoEntry(id: RowId(3), content: 'content'));

      b.update(db.users, const UsersCompanion(name: Value('new user name')));
      b.replace(
        db.todosTable,
        const TodosTableCompanion(id: Value(RowId(3)), content: Value('new')),
      );

      b.deleteWhere(db.todosTable, (TodosTable row) => row.id.equals(3));
      b.delete(db.todosTable, const TodosTableCompanion(id: Value(RowId(3))));
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

  test('uses nested transactions', () async {
    final transactions = executor.transactions;
    when(transactions.begin(any))
        .thenAnswer((_) async => MockSession(isTransaction: true));

    await db.transaction(() async {
      await db.batch((batch) {});
      await db.batch((batch) {});
    });

    verify(executor.begin(any)).called(1);
    verify(transactions.begin(any)).called(2);
  });

  test('starts a new transaction when not running in a transaction', () async {
    await db.batch((batch) {});

    verify(executor.begin(any)).called(1);
  });

  test('can get results', () async {
    late BatchedStatement stmt;

    final transactions = executor.transactions;
    when(transactions.executeBatch(any)).thenAnswer((_) async {
      return [queryResult([], affectedRows: 42)];
    });

    final results = await db.batch((b) {
      stmt = b.deleteAll(db.categories);
    });

    expect(stmt.resolveResult(results).affectedRows, 42);
  });
}
