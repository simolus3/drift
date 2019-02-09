import 'package:mockito/mockito.dart';
import 'package:sally/sally.dart';
import 'package:test_api/test_api.dart';

import 'generated_tables.dart';

// used so that we can mock the SqlExecutor typedef
abstract class SqlExecutorAsClass {
  Future<void> call(String sql);
}

class MockQueryExecutor extends Mock implements SqlExecutorAsClass {}

void main() {
  Migrator migrator;
  TestDatabase db;
  MockQueryExecutor executor;

  setUp(() {
    executor = MockQueryExecutor();
    db = TestDatabase(null);
    migrator = Migrator(db, executor);
  });

  test('generates CREATE TABLE statements', () {
    migrator.createAllTables();

    verify(executor.call('CREATE TABLE IF NOT EXISTS users (id INTEGER NOT NULL , name VARCHAR NOT NULL , is_awesome BOOLEAN NULL CHECK (is_awesome in (0, 1)))'));
  });

  test('generates DROP TABLE statements', () {
    migrator.deleteTable('users');

    verify(executor.call('DROP TABLE IF EXISTS users'));
  });

  test('generates ALTER TABLE statements to add columns', () {
    migrator.addColumn(db.users, db.users.isAwesome);

    verify(executor.call('ALTER TABLE users ADD COLUMN is_awesome BOOLEAN NULL CHECK (is_awesome in (0, 1))'));
  });
}