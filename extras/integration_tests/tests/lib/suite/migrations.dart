import 'package:test/test.dart';
import 'package:tests/data/sample_data.dart' as people;
import 'package:tests/database/database.dart';
import 'package:tests/tests.dart';

import 'suite.dart';

void migrationTests(TestExecutor executor) {
  test('creates users table when opening version 1', () async {
    final database = Database(executor.createConnection(), schemaVersion: 1);

    // we write 3 users when the database is created
    final count = await database.userCount().getSingle();
    expect(count, 3);

    await executor.clearDatabaseAndClose(database);
  });

  test('saves and restores database', () async {
    var database = Database(executor.createConnection(), schemaVersion: 1);
    await database.writeUser(people.florian);
    await database.close();

    database = Database(executor.createConnection(), schemaVersion: 2);

    // the 3 initial users plus People.florian
    final count = await database.userCount().getSingle();
    expect(count, 4);
    expect(database.schemaVersionChangedFrom, 1);
    expect(database.schemaVersionChangedTo, 2);

    await executor.clearDatabaseAndClose(database);
  });

  test('can use destructive migration', () async {
    final old = Database(executor.createConnection(), schemaVersion: 1);
    await old.executor.ensureOpen(old);
    await old.close();

    final database = Database(executor.createConnection(), schemaVersion: 2);
    database.overrideMigration = database.destructiveFallback;

    // No users now, we deleted everything
    final count = await database.userCount().getSingle();
    expect(count, 0);

    await executor.clearDatabaseAndClose(database);
  });

  test('runs the migrator when downgrading', () async {
    var database = Database(executor.createConnection(), schemaVersion: 2);
    await database.executor.ensureOpen(database); // Create the database
    await database.close();

    database = Database(executor.createConnection(), schemaVersion: 1);
    await database.executor.ensureOpen(database); // Let the migrator run

    expect(database.schemaVersionChangedFrom, 2);
    expect(database.schemaVersionChangedTo, 1);

    await executor.clearDatabaseAndClose(database);
  });

  test('does not apply schema version when migration throws', () async {
    var database = Database(executor.createConnection(), schemaVersion: 1);
    await database.executor.ensureOpen(database); // Create the database
    await database.close();

    database = Database(executor.createConnection(), schemaVersion: 2);
    database.overrideMigration = MigrationStrategy(
      onUpgrade: (m, from, to) => Future.error('oops'),
    );

    try {
      await database.executor.ensureOpen(database);
      fail('Should have thrown');
    } catch (e) {
      //ignore
      await database.close();
    }

    // Open it one last time, the schema version should still be at 1
    database = Database(executor.createConnection(), schemaVersion: 1);

    QueryRow result;
    if (database.executor.dialect == SqlDialect.sqlite) {
      result = await database.customSelect('PRAGMA user_version').getSingle();
    } else {
      result = await database
          .customSelect('SELECT version FROM __schema')
          .getSingle();
    }
    expect(result.data.values.single, 1);

    await executor.clearDatabaseAndClose(database);
  });
}
