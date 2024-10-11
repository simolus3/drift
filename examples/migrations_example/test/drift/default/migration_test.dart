// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:migrations_example/database.dart';
import 'package:test/test.dart';
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

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    final versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = Database(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // Simple tests ensure the schema is transformed correctly, but some
  // migrations benefit from a test verifying that data is transformed correctly
  // too. This is particularly true for migrations that change existing columns
  // (e.g. altering their type or constraints). Migrations that only add tables
  // or columns typically don't need these advanced tests.
  test("migration from v1 to v2 does not corrupt data", () async {
    final oldUsersData = <v1.UsersData>[v1.UsersData(id: 1)];
    final expectedNewUsersData = <v2.UsersData>[
      v2.UsersData(id: 1, name: 'no name')
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: Database.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.users, oldUsersData);
      },
      validateItems: (newDb) async {
        expect(expectedNewUsersData, await newDb.select(newDb.users).get());
      },
    );
  });

  test('foreign key constraints work after upgrade from v4 to v5', () async {
    final schema = await verifier.schemaAt(4);
    final db = Database(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);
    await db.close();

    // Test that the foreign key reference introduced in v5 works as expected.
    final migratedDb = v5.DatabaseAtV5(schema.newConnection());
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

    final oldDb = v4.DatabaseAtV4(schema.newConnection());
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
    final migratedDb = v5.DatabaseAtV5(schema.newConnection());
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
