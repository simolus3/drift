import 'package:moor/moor.dart';
import 'package:test_api/test_api.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockQueryExecutor mockQueryExecutor;

  setUp(() {
    mockQueryExecutor = MockQueryExecutor();
    db = TodoDb(null);
  });

  group('Migrations', () {
    test('creates all tables', () async {
      await Migrator(db, mockQueryExecutor).createAllTables();

      // should create todos, categories, users and shared_todos table
      verify(mockQueryExecutor.call('CREATE TABLE IF NOT EXISTS todos '
          '(id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR NULL, '
          'content VARCHAR NOT NULL, target_date INTEGER NULL, '
          'category INTEGER NULL);'));

      verify(mockQueryExecutor.call('CREATE TABLE IF NOT EXISTS categories '
          '(id INTEGER PRIMARY KEY AUTOINCREMENT, `desc` VARCHAR NOT NULL);'));

      verify(mockQueryExecutor.call('CREATE TABLE IF NOT EXISTS users '
          '(id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR NOT NULL, '
          'is_awesome BOOLEAN NOT NULL CHECK (is_awesome in (0, 1)), '
          'profile_picture BLOB NOT NULL);'));

      verify(mockQueryExecutor.call('CREATE TABLE IF NOT EXISTS shared_todos '
          '(todo INTEGER NOT NULL, user INTEGER NOT NULL, PRIMARY KEY (todo, user));'));
    });

    test('creates individual tables', () async {
      await Migrator(db, mockQueryExecutor).createTable(db.users);

      verify(mockQueryExecutor.call('CREATE TABLE IF NOT EXISTS users '
          '(id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR NOT NULL, '
          'is_awesome BOOLEAN NOT NULL CHECK (is_awesome in (0, 1)), '
          'profile_picture BLOB NOT NULL);'));
    });

    test('drops tables', () async {
      await Migrator(db, mockQueryExecutor).deleteTable('users');

      verify(mockQueryExecutor.call('DROP TABLE IF EXISTS users;'));
    });

    test('adds columns', () async {
      await Migrator(db, mockQueryExecutor)
          .addColumn(db.users, db.users.isAwesome);

      verify(mockQueryExecutor.call('ALTER TABLE users ADD COLUMN '
          'is_awesome BOOLEAN NOT NULL CHECK (is_awesome in (0, 1));'));
    });
  });
}
