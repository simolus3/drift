import 'package:moor/moor.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  QueryExecutor mockExecutor;

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
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title VARCHAR NULL, '
          'content VARCHAR NOT NULL, target_date INTEGER NULL, '
          'category INTEGER NULL);',
          []));

      verify(mockExecutor.runCustom(
          'CREATE TABLE IF NOT EXISTS categories '
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          '`desc` VARCHAR NOT NULL UNIQUE, '
          'priority INTEGER NOT NULL DEFAULT 0);',
          []));

      verify(mockExecutor.runCustom(
          'CREATE TABLE IF NOT EXISTS users '
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'name VARCHAR NOT NULL, '
          'is_awesome INTEGER NOT NULL DEFAULT 1 CHECK (is_awesome in (0, 1)), '
          'profile_picture BLOB NOT NULL, '
          'creation_time INTEGER NOT NULL '
          "DEFAULT (strftime('%s', CURRENT_TIMESTAMP)));",
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
          'custom VARCHAR NOT NULL'
          ');',
          []));
    });

    test('creates individual tables', () async {
      await db.createMigrator().createTable(db.users);

      verify(mockExecutor.runCustom(
          'CREATE TABLE IF NOT EXISTS users '
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'name VARCHAR NOT NULL, '
          'is_awesome INTEGER NOT NULL DEFAULT 1 CHECK (is_awesome in (0, 1)), '
          'profile_picture BLOB NOT NULL, '
          'creation_time INTEGER NOT NULL '
          "DEFAULT (strftime('%s', CURRENT_TIMESTAMP)));",
          []));
    });

    test('drops tables', () async {
      await db.createMigrator().deleteTable('users');

      verify(mockExecutor.runCustom('DROP TABLE IF EXISTS users;'));
    });

    test('adds columns', () async {
      await db.createMigrator().addColumn(db.users, db.users.isAwesome);

      verify(mockExecutor.runCustom('ALTER TABLE users ADD COLUMN '
          'is_awesome INTEGER NOT NULL DEFAULT 1 '
          'CHECK (is_awesome in (0, 1));'));
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
    TodoDb db;
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
}

class _DefaultDb extends GeneratedDatabase {
  _DefaultDb(QueryExecutor executor)
      // ignore: prefer_const_constructors
      : super(SqlTypeSystem.withDefaults(), executor);

  @override
  List<TableInfo<Table, DataClass>> get allTables => [];

  @override
  int get schemaVersion => 2;
}
