import 'package:drift/native.dart';
import 'package:migrations_example/database.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';
import 'package:drift_dev/api/migrations.dart';

// Import the generated schema helper to instantiate databases at old versions.
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Test all possible schema migrations with a simple test that just ensures
  // the schema is correct after the migration.
  // More complex tests ensuring data integrity are written below.
  group('general migration', () {
    const currentSchema = 7;

    for (var oldVersion = 1; oldVersion < currentSchema; oldVersion++) {
      group('from v$oldVersion', () {
        for (var targetVersion = oldVersion + 1;
            targetVersion <= currentSchema;
            targetVersion++) {
          test('to v$targetVersion', () async {
            final connection = await verifier.startAt(oldVersion);
            final db = Database(connection);
            addTearDown(db.close);

            await verifier.migrateAndValidate(db, targetVersion);
          });
        }
      });
    }
  });

  test('preserves existing data in migration from v1 to v2', () async {
    final schema = await verifier.schemaAt(1);

    // Add some data to the users table, which only has an id column at v1
    final oldDb = v1.DatabaseAtV1.connect(schema.newConnection());
    await oldDb.into(oldDb.users).insert(const v1.UsersCompanion(id: Value(1)));
    await oldDb.close();

    // Run the migration and verify that it adds the name column.
    final db = Database(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    await db.close();

    // Make sure the user is still here
    final migratedDb = v2.DatabaseAtV2.connect(schema.newConnection());
    final user = await migratedDb.select(migratedDb.users).getSingle();
    expect(user.id, 1);
    expect(user.name, 'no name'); // default from the migration
    await migratedDb.close();
  });

  test('foreign key constraints work after upgrade from v4 to v5', () async {
    final schema = await verifier.schemaAt(4);
    final db = Database(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);
    await db.close();

    // Test that the foreign key reference introduced in v5 works as expected.
    final migratedDb = v5.DatabaseAtV5.connect(schema.newConnection());
    // The `foreign_keys` pragma is a per-connection option and the generated
    // versioned classes don't enable it by default. So, enable it manually.
    await migratedDb.customStatement('pragma foreign_keys = on;');
    await migratedDb.into(migratedDb.users).insert(v5.UsersCompanion.insert());
    await migratedDb
        .into(migratedDb.users)
        .insert(v5.UsersCompanion.insert(nextUser: Value(1)));

    // Deleting the first user should now fail due to the constraint
    await expectLater(migratedDb.users.deleteWhere((tbl) => tbl.id.equals(1)),
        throwsA(isA<SqliteException>()));
  });

  test('view works after upgrade from v4 to v5', () async {
    final schema = await verifier.schemaAt(4);

    final oldDb = v4.DatabaseAtV4.connect(schema.newConnection());
    await oldDb.batch((batch) {
      batch
        ..insert(oldDb.users, v4.UsersCompanion.insert(id: Value(1)))
        ..insert(oldDb.users, v4.UsersCompanion.insert(id: Value(2)))
        ..insert(
            oldDb.groups, v4.GroupsCompanion.insert(title: 'Test', owner: 1));
    });
    await oldDb.close();

    // Run the migration and verify that it adds the view.
    final db = Database(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);
    await db.close();

    // Make sure the view works!
    final migratedDb = v5.DatabaseAtV5.connect(schema.newConnection());
    final viewCount = await migratedDb.select(migratedDb.groupCount).get();

    expect(
        viewCount,
        contains(isA<v5.GroupCountData>()
            .having((e) => e.id, 'id', 1)
            .having((e) => e.groupCount, 'groupCount', 1)));
    expect(
        viewCount,
        contains(isA<v5.GroupCountData>()
            .having((e) => e.id, 'id', 2)
            .having((e) => e.groupCount, 'groupCount', 0)));
    await migratedDb.close();
  });
}
