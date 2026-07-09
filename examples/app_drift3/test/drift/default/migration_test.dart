// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:app/database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v3.dart' as v3;

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
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test("migration from v1 to v3 does not corrupt data", () async {
    final oldCategoriesData = <v1.CategoriesData>[];
    final expectedNewCategoriesData = <v3.CategoriesData>[];

    final oldTodoEntriesData = <v1.TodoEntriesData>[
      const v1.TodoEntriesData(description: 'My manually added entry', id: 1)
    ];
    final expectedNewTodoEntriesData = <v3.TodoEntriesData>[
      const v3.TodoEntriesData(
        description: 'My manually added entry',
        id: 1,
      )
    ];

    final oldTextEntriesData = <v1.TextEntriesData>[];
    final expectedNewTextEntriesData = <v3.TextEntriesData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 3,
      createOld: v1.DatabaseAtV1.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.categories, oldCategoriesData);
        batch.insertAll(oldDb.todoEntries, oldTodoEntriesData);
      },
      validateItems: (newDb) async {
        expect(expectedNewCategoriesData,
            await newDb.select(newDb.categories).get());
        expect(expectedNewTodoEntriesData,
            await newDb.select(newDb.todoEntries).get());
      },
    );
  });
}
