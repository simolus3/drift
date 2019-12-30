import 'package:moor/moor.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockQueryExecutor mockQueryExecutor;
  QueryExecutor mockExecutor;

  setUp(() {
    mockQueryExecutor = MockQueryExecutor();
    mockExecutor = MockExecutor();
    db = TodoDb(mockExecutor);
  });

  group('Migrations', () {
    test('creates all tables', () async {
      await db.handleDatabaseCreation(executor: mockQueryExecutor);

      // should create todos, categories, users and shared_todos table
      verify(mockQueryExecutor.call(
          'CREATE TABLE IF NOT EXISTS todos '
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title VARCHAR NULL, '
          'content VARCHAR NOT NULL, target_date INTEGER NULL, '
          'category INTEGER NULL);',
          []));

      verify(mockQueryExecutor.call(
          'CREATE TABLE IF NOT EXISTS categories '
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          '`desc` VARCHAR NOT NULL UNIQUE);',
          []));

      verify(mockQueryExecutor.call(
          'CREATE TABLE IF NOT EXISTS users '
          '(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'name VARCHAR NOT NULL, '
          'is_awesome INTEGER NOT NULL DEFAULT 1 CHECK (is_awesome in (0, 1)), '
          'profile_picture BLOB NOT NULL, '
          'creation_time INTEGER NOT NULL '
          "DEFAULT (strftime('%s', CURRENT_TIMESTAMP)));",
          []));

      verify(mockQueryExecutor.call(
          'CREATE TABLE IF NOT EXISTS shared_todos ('
          'todo INTEGER NOT NULL, '
          'user INTEGER NOT NULL, '
          'PRIMARY KEY (todo, user), '
          'FOREIGN KEY (todo) REFERENCES todos(id), '
          'FOREIGN KEY (user) REFERENCES users(id)'
          ');',
          []));

      verify(mockQueryExecutor.call(
          'CREATE TABLE IF NOT EXISTS '
          'table_without_p_k ('
          'not_really_an_id INTEGER NOT NULL, '
          'some_float REAL NOT NULL, '
          'custom VARCHAR NOT NULL'
          ');',
          []));
    });

    test('creates individual tables', () async {
      await Migrator(db, mockQueryExecutor).createTable(db.users);

      verify(mockQueryExecutor.call(
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
      await Migrator(db, mockQueryExecutor).deleteTable('users');

      verify(mockQueryExecutor.call('DROP TABLE IF EXISTS users;'));
    });

    test('adds columns', () async {
      await Migrator(db, mockQueryExecutor)
          .addColumn(db.users, db.users.isAwesome);

      verify(mockQueryExecutor.call('ALTER TABLE users ADD COLUMN '
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
        () => db.handleDatabaseVersionChange(
            executor: MockQueryExecutor(), from: 1, to: 2),
        throwsA(const TypeMatcher<Exception>()));
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
