import 'package:sally/sally.dart';
import 'package:test_api/test_api.dart';

import 'tables/todos.dart';
import 'utils/mocks.dart';

void main() {
  TodoDb db;
  MockQueryExecutor mockQueryExecutor;

  setUp(() {
    db = TodoDb(null);
    mockQueryExecutor = MockQueryExecutor();
  });

  group('Migrations', () {
    test('creates all tables', () async {
      await Migrator(db, mockQueryExecutor).createAllTables();

      // should create todos, categories and users table
      verify(mockQueryExecutor.call('CREATE TABLE IF NOT EXISTS todos '
          '(id INTEGER NOT NULL AUTO INCREMENT, title VARCHAR NULL,'
          ' content VARCHAR NOT NULL, category INTEGER NULL);'));

      verify(mockQueryExecutor.call('CREATE TABLE IF NOT EXISTS categories '
          '(id INTEGER NOT NULL AUTO INCREMENT, `desc` VARCHAR NOT NULL);'));

      verify(mockQueryExecutor.call('CREATE TABLE IF NOT EXISTS users '
          '(id INTEGER NOT NULL AUTO INCREMENT, name VARCHAR NOT NULL, '
          'is_awesome BOOLEAN NOT NULL CHECK (is_awesome in (0, 1)));'));
    });

    test('creates individual tables', () async {
      await Migrator(db, mockQueryExecutor).createTable(db.users);

      verify(mockQueryExecutor.call('CREATE TABLE IF NOT EXISTS users '
          '(id INTEGER NOT NULL AUTO INCREMENT, name VARCHAR NOT NULL, '
          'is_awesome BOOLEAN NOT NULL CHECK (is_awesome in (0, 1)));'));
    });

    test('drops tables', () async {
      await Migrator(db, mockQueryExecutor).deleteTable('users');

      verify(mockQueryExecutor.call('DROP TABLE IF EXISTS users;'));
    });

    test('adds columns', () async {
      await Migrator(db, mockQueryExecutor).addColumn(db.users, db.users.isAwesome);

      verify(mockQueryExecutor.call('ALTER TABLE users ADD COLUMN '
          'is_awesome BOOLEAN NOT NULL CHECK (is_awesome in (0, 1));'));
    });
  });
}