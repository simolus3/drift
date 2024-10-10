// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:migrations_example/database.dart';
import 'package:test/test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('default database', () {
    //////////////////////////////////////////////////////////////////////////////
    ////////////////////// GENERATED TESTS - DO NOT MODIFY ///////////////////////
    //////////////////////////////////////////////////////////////////////////////
    if (GeneratedHelper.versions.length < 2) return;
    for (var i
        in List.generate(GeneratedHelper.versions.length - 1, (i) => i)) {
      final oldVersion = GeneratedHelper.versions.elementAt(i);
      final newVersion = GeneratedHelper.versions.elementAt(i + 1);
      test("migrate from v$oldVersion to v$newVersion", () async {
        final schema = await verifier.schemaAt(oldVersion);
        final db = Database(schema.newConnection());
        await verifier.migrateAndValidate(db, newVersion);
        await db.close();
      });
    }
    //////////////////////////////////////////////////////////////////////////////
    /////////////////////// END OF GENERATED TESTS ///////////////////////////////
    //////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////
    ///////////////////// CUSTOM TESTS - MODIFY AS NEEDED ////////////////////////
    //////////////////////////////////////////////////////////////////////////////
    test("migration from v1 to v2 does not corrupt data", () async {
      // TODO: Consider writing these kinds of tests when altering tables in a way that might affect existing rows.
      // The automatically generated migration tests run with an empty schema, so it's a recommended practice to also test with
      // data for relevant migrations.
      final oldUsersData = <v1
          .UsersData>[]; // TODO: Add expected data at version 1 using v1.UsersData
      final expectedNewUsersData = <v2
          .UsersData>[]; // TODO: Add expected data at version 2 using v2.UsersData

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        verifier: verifier,
        createOld: (e) => v1.DatabaseAtV1(e),
        createNew: (e) => v2.DatabaseAtV2(e),
        openTestedDatabase: (e) => Database(e),
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.users, oldUsersData);
        },
        validateItems: (newDb) async {
          expect(expectedNewUsersData, await newDb.select(newDb.users).get());
        },
      );
    });
    ///////////////////////////////////////////////////////////////////////////////
    /////////////////////// END OF CUSTOM TESTS ///////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////
  });
}
