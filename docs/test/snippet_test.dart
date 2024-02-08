import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_docs/snippets/dart_api/datetime_conversion.dart';
import 'package:drift_docs/snippets/log_interceptor.dart';
import 'package:drift_docs/snippets/modular/schema_inspection.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;
import 'package:test/test.dart';

import 'generated/database.dart';

/// Test for some snippets embedded on https://drift.simonbinder.eu to make sure
/// that they are still up to date and work as intended with the latest drift
/// version.
void main() {
  group('changing datetime format', () {
    test('unix timestamp to text', () async {
      final db = Database(DatabaseConnection(NativeDatabase.memory()));
      addTearDown(db.close);

      final time = DateTime.fromMillisecondsSinceEpoch(
        // Drop milliseconds which are not supported by the old format
        1000 * (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      );

      // The database is currently using unix timstamps. Let's add some rows in
      // that format:
      await db.users.insertOne(
          UsersCompanion.insert(name: 'name', createdAt: Value(time)));
      await db.users.insertOne(
          UsersCompanion.insert(name: 'name2', createdAt: Value(null)));

      // Run conversion from unix timestamps to text
      await db.migrateFromUnixTimestampsToText(db.createMigrator());

      // Check that the values are still there!
      final rows = await (db.select(db.users)
            ..orderBy([(row) => OrderingTerm.asc(row.rowId)]))
          .get();

      expect(rows, [
        User(id: 1, name: 'name', createdAt: time),
        const User(id: 2, name: 'name2', createdAt: null),
      ]);
    });

    test('text to unix timestamp', () async {
      // First, create all tables using text as datetime
      final nativeDatabase = sqlite3.openInMemory();
      var db = Database(DatabaseConnection(NativeDatabase.opened(nativeDatabase,
          closeUnderlyingOnClose: false)));
      db.options = const DriftDatabaseOptions(storeDateTimeAsText: true);

      final time = DateTime.fromMillisecondsSinceEpoch(
          1000 * (DateTime.now().millisecondsSinceEpoch ~/ 1000));

      // Add rows, storing date time as text
      await db.users.insertOne(
          UsersCompanion.insert(name: 'name', createdAt: Value(time)));
      await db.users.insertOne(
          UsersCompanion.insert(name: 'name2', createdAt: Value(null)));
      await db.close();

      db = Database(DatabaseConnection(
          NativeDatabase.opened(nativeDatabase, closeUnderlyingOnClose: true)));
      addTearDown(db.close);

      // Next, migrate back to unix timestamps
      db.options = const DriftDatabaseOptions(storeDateTimeAsText: false);
      final migrator = db.createMigrator();
      await db.migrateFromTextDateTimesToUnixTimestamps(migrator);

      final rows = await (db.select(db.users)
            ..orderBy([(row) => OrderingTerm.asc(row.rowId)]))
          .get();

      expect(rows, [
        User(id: 1, name: 'name', createdAt: time),
        const User(id: 2, name: 'name2', createdAt: null),
      ]);
    });

    test('text to unix timestamp, support old sqlite', () async {
      // First, create all tables using datetime as text
      final nativeDatabase = sqlite3.openInMemory();
      var db = Database(DatabaseConnection(NativeDatabase.opened(nativeDatabase,
          closeUnderlyingOnClose: false)));
      db.options = const DriftDatabaseOptions(storeDateTimeAsText: true);

      final time = DateTime.fromMillisecondsSinceEpoch(
          1000 * (DateTime.now().millisecondsSinceEpoch ~/ 1000));

      // Add rows, storing date time as text
      await db.users.insertOne(
          UsersCompanion.insert(name: 'name', createdAt: Value(time)));
      await db.users.insertOne(
          UsersCompanion.insert(name: 'name2', createdAt: Value(null)));
      await db.close();

      db = Database(DatabaseConnection(
          NativeDatabase.opened(nativeDatabase, closeUnderlyingOnClose: true)));
      addTearDown(db.close);

      // Next, migrate back to unix timestamps
      db.options = const DriftDatabaseOptions(storeDateTimeAsText: false);
      final migrator = db.createMigrator();
      await db.migrateFromTextDateTimesToUnixTimestampsPre338(migrator);

      final rows = await (db.select(db.users)
            ..orderBy([(row) => OrderingTerm.asc(row.rowId)]))
          .get();

      expect(rows, [
        User(id: 1, name: 'name', createdAt: time),
        const User(id: 2, name: 'name2', createdAt: null),
      ]);
    });
  });

  group('runtime schema inspection', () {
    test('findById', () async {
      final db = Database(NativeDatabase.memory());
      addTearDown(db.close);

      await db.batch((batch) {
        batch.insert(db.users, UsersCompanion.insert(name: 'foo')); // 1
        batch.insert(db.users, UsersCompanion.insert(name: 'bar')); // 2
        batch.insert(db.users, UsersCompanion.insert(name: 'baz')); // 3
      });

      final row = await db.users.findById(2).getSingle();
      expect(row.name, 'bar');
    });
  });

  test('interceptor', () {
    expect(
      () async {
        final db =
            Database(NativeDatabase.memory().interceptWith(LogInterceptor()));

        await db.batch((batch) {
          batch.insert(db.users, UsersCompanion.insert(name: 'foo'));
        });

        await db.users.all().get();
      },
      prints(
        allOf(
          stringContainsInOrder(
            [
              'begin',
              'Running batch with BatchedStatements',
              ' => succeeded after ',
              'Running commit',
              ' => succeeded after ',
              'Running SELECT * FROM "users"; with []',
              ' => succeeded after'
            ],
          ),
        ),
      ),
    );
  });
}
