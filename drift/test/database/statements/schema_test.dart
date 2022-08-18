import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late QueryExecutor mockExecutor;

  setUp(() {
    mockExecutor = MockExecutor();
    db = TodoDb(mockExecutor);
  });

  group('Migrations', () {
    test('creates all tables', () async {
      await db.beforeOpen(mockExecutor, const OpeningDetails(null, 1));

      // should create todos, categories, users and shared_todos table
      verify(mockExecutor.runCustom(
          'CREATE TABLE IF NOT EXISTS todos '
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TEXT NULL, '
          'content TEXT NOT NULL, target_date INTEGER NULL UNIQUE, '
          'category INTEGER NULL REFERENCES categories (id), '
          'UNIQUE (title, category), UNIQUE (title, target_date));',
          []));

      verify(mockExecutor.runCustom(
          'CREATE TABLE IF NOT EXISTS categories '
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          '"desc" TEXT NOT NULL UNIQUE, '
          'priority INTEGER NOT NULL DEFAULT 0, '
          'description_in_upper_case TEXT NOT NULL GENERATED ALWAYS AS '
          '(UPPER("desc")) VIRTUAL'
          ');',
          []));

      verify(mockExecutor.runCustom(
          'CREATE TABLE IF NOT EXISTS users ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL UNIQUE, '
          'is_awesome INTEGER NOT NULL DEFAULT 1 CHECK (is_awesome IN (0, 1)), '
          'profile_picture BLOB NOT NULL, '
          'creation_time INTEGER NOT NULL '
          "DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) "
          'CHECK(creation_time > -631152000)'
          ');',
          []));

      verify(mockExecutor.runCustom(
          'CREATE TABLE IF NOT EXISTS shared_todos ('
          'todo INTEGER NOT NULL, '
          'user INTEGER NOT NULL, '
          'PRIMARY KEY (todo, user), '
          'FOREIGN KEY (todo) REFERENCES todos(id), '
          'FOREIGN KEY (user) REFERENCES users(id)'
          ');',
          []));

      verify(mockExecutor.runCustom(
          'CREATE TABLE IF NOT EXISTS '
          'table_without_p_k ('
          'not_really_an_id INTEGER NOT NULL, '
          'some_float REAL NOT NULL, '
          'web_safe_int INTEGER NULL, '
          'custom TEXT NOT NULL'
          ');',
          []));

      verify(mockExecutor.runCustom(
          'CREATE VIEW IF NOT EXISTS category_todo_count_view '
          '(description, item_count) AS SELECT '
          't1."desc" || \'!\' AS "description", '
          'COUNT(t0.id) AS "item_count" '
          'FROM categories t1 '
          'INNER JOIN todos t0 '
          'ON t0.category = t1.id '
          'GROUP BY t1.id',
          []));

      verify(mockExecutor.runCustom(
          'CREATE VIEW IF NOT EXISTS todo_with_category_view '
          '(title, "desc") AS SELECT '
          't0.title AS "t0.title", '
          't1."desc" AS "t1.desc" '
          'FROM todos t0 '
          'INNER JOIN categories t1 '
          'ON t1.id = t0.category',
          []));
    });

    test('creates individual tables', () async {
      await db.createMigrator().createTable(db.users);

      verify(mockExecutor.runCustom(
          'CREATE TABLE IF NOT EXISTS users '
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL UNIQUE, '
          'is_awesome INTEGER NOT NULL DEFAULT 1 CHECK (is_awesome IN (0, 1)), '
          'profile_picture BLOB NOT NULL, '
          'creation_time INTEGER NOT NULL '
          "DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) "
          'CHECK(creation_time > -631152000)'
          ');',
          []));
    });

    test('creates views through create()', () async {
      await db.createMigrator().create(db.categoryTodoCountView);

      verify(mockExecutor.runCustom(
          'CREATE VIEW IF NOT EXISTS category_todo_count_view '
          '(description, item_count) AS SELECT '
          't1."desc" || \'!\' AS "description", '
          'COUNT(t0.id) AS "item_count" '
          'FROM categories t1 '
          'INNER JOIN todos t0 '
          'ON t0.category = t1.id '
          'GROUP BY t1.id',
          []));
    });

    test('drops tables', () async {
      await db.createMigrator().deleteTable('users');

      verify(mockExecutor.runCustom('DROP TABLE IF EXISTS users;'));
    });

    test('drops indices', () async {
      await db.createMigrator().drop(Index('desc', 'foo'));

      verify(mockExecutor.runCustom('DROP INDEX IF EXISTS "desc";'));
    });

    test('drops triggers', () async {
      await db.createMigrator().drop(Trigger('foo', 'my_trigger'));

      verify(mockExecutor.runCustom('DROP TRIGGER IF EXISTS my_trigger;'));
    });

    test('adds columns', () async {
      await db.createMigrator().addColumn(db.users, db.users.isAwesome);

      verify(mockExecutor.runCustom('ALTER TABLE users ADD COLUMN '
          'is_awesome INTEGER NOT NULL DEFAULT 1 '
          'CHECK (is_awesome IN (0, 1));'));
    });

    test('renames columns', () async {
      await db
          .createMigrator()
          .renameColumn(db.users, 'my name', db.users.name);

      verify(mockExecutor
          .runCustom('ALTER TABLE users RENAME COLUMN "my name" TO name;'));
    });
  });

  test('custom statements', () async {
    await db.customStatement('some custom statement');
    verify(mockExecutor.runCustom('some custom statement'));
  });

  test('upgrading a database without schema migration throws', () async {
    final db = _DefaultDb(MockExecutor());
    expect(
      () => db.beforeOpen(db.executor, const OpeningDetails(2, 3)),
      throwsA(const TypeMatcher<Exception>()),
    );
  });

  test('can use migrations inside schema callbacks', () async {
    final executor = MockExecutor();
    late TodoDb db;
    db = TodoDb(executor)
      ..migration = MigrationStrategy(onUpgrade: (m, from, to) async {
        await db.transaction(() async {
          await m.createTable(db.users);
        });
      });

    await db.beforeOpen(executor, const OpeningDetails(2, 3));

    verify(executor.beginTransaction());
    verify(executor.transactions.runCustom(any, any));
    verifyNever(executor.runCustom(any, any));
  });

  test('removes variables in `CREATE TABLE` statements', () async {
    final executor = MockExecutor();
    final db = _DefaultDb(executor);

    late GeneratedColumn<int> column;
    column = GeneratedColumn<int>(
      'foo',
      'foo',
      true,
      type: DriftSqlType.int,
      check: () => column.isSmallerThan(const Variable(3)),
    );
    final table = CustomTable('foo', db, [column]);

    await db.createMigrator().createTable(table);
    await db.close();

    // This should not attempt to generate a parameter (`?`)
    // https://github.com/simolus3/drift/discussions/1936
    verify(executor.runCustom(argThat(contains('CHECK(foo < 3)')), []));
  });
}

class _DefaultDb extends GeneratedDatabase {
  _DefaultDb(QueryExecutor executor) : super(executor);

  @override
  List<TableInfo<Table, DataClass>> get allTables => [];

  @override
  int get schemaVersion => 2;
}
