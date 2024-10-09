// ignore_for_file: unused_local_variable, unused_import
// GENERATED CODE, DO NOT EDIT BY HAND.
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:migrations_example/database.dart';
import 'package:test/test.dart';
import 'schemas/schema.dart';

import 'schemas/schema_v1.dart' as v1;
import 'schemas/schema_v2.dart' as v2;
import 'validation/v1_to_v2.dart' as v1_to_v2;
import 'schemas/schema_v3.dart' as v3;
import 'validation/v2_to_v3.dart' as v2_to_v3;
import 'schemas/schema_v4.dart' as v4;
import 'validation/v3_to_v4.dart' as v3_to_v4;
import 'schemas/schema_v5.dart' as v5;
import 'validation/v4_to_v5.dart' as v4_to_v5;
import 'schemas/schema_v6.dart' as v6;
import 'validation/v5_to_v6.dart' as v5_to_v6;
import 'schemas/schema_v7.dart' as v7;
import 'validation/v6_to_v7.dart' as v6_to_v7;
import 'schemas/schema_v8.dart' as v8;
import 'validation/v7_to_v8.dart' as v7_to_v8;
import 'schemas/schema_v9.dart' as v9;
import 'validation/v8_to_v9.dart' as v8_to_v9;
import 'schemas/schema_v10.dart' as v10;
import 'validation/v9_to_v10.dart' as v9_to_v10;
import 'schemas/schema_v11.dart' as v11;
import 'validation/v10_to_v11.dart' as v10_to_v11;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test(
      "default - migrate from v1 to v2",
      () => testWithDataIntegrity(
            from: 1,
            to: 2,
            verifier: verifier,
            createOld: (e) => v1.DatabaseAtV1(e),
            createNew: (e) => v2.DatabaseAtV2(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v1_to_v2.usersV1);
            },
            validateItems: (newDb) async {
              expect(v1_to_v2.usersV2, await newDb.select(newDb.users).get());
            },
          ));

  test(
      "default - migrate from v2 to v3",
      () => testWithDataIntegrity(
            from: 2,
            to: 3,
            verifier: verifier,
            createOld: (e) => v2.DatabaseAtV2(e),
            createNew: (e) => v3.DatabaseAtV3(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v2_to_v3.usersV2);
            },
            validateItems: (newDb) async {
              expect(v2_to_v3.usersV3, await newDb.select(newDb.users).get());
            },
          ));

  test(
      "default - migrate from v3 to v4",
      () => testWithDataIntegrity(
            from: 3,
            to: 4,
            verifier: verifier,
            createOld: (e) => v3.DatabaseAtV3(e),
            createNew: (e) => v4.DatabaseAtV4(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v3_to_v4.usersV3);
              b.insertAll(oldDb.groups, v3_to_v4.groupsV3);
            },
            validateItems: (newDb) async {
              expect(v3_to_v4.usersV4, await newDb.select(newDb.users).get());
              expect(v3_to_v4.groupsV4, await newDb.select(newDb.groups).get());
            },
          ));

  test(
      "default - migrate from v4 to v5",
      () => testWithDataIntegrity(
            from: 4,
            to: 5,
            verifier: verifier,
            createOld: (e) => v4.DatabaseAtV4(e),
            createNew: (e) => v5.DatabaseAtV5(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v4_to_v5.usersV4);
              b.insertAll(oldDb.groups, v4_to_v5.groupsV4);
            },
            validateItems: (newDb) async {
              expect(v4_to_v5.usersV5, await newDb.select(newDb.users).get());
              expect(v4_to_v5.groupsV5, await newDb.select(newDb.groups).get());
            },
          ));

  test(
      "default - migrate from v5 to v6",
      () => testWithDataIntegrity(
            from: 5,
            to: 6,
            verifier: verifier,
            createOld: (e) => v5.DatabaseAtV5(e),
            createNew: (e) => v6.DatabaseAtV6(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v5_to_v6.usersV5);
              b.insertAll(oldDb.groups, v5_to_v6.groupsV5);
            },
            validateItems: (newDb) async {
              expect(v5_to_v6.usersV6, await newDb.select(newDb.users).get());
              expect(v5_to_v6.groupsV6, await newDb.select(newDb.groups).get());
            },
          ));

  test(
      "default - migrate from v6 to v7",
      () => testWithDataIntegrity(
            from: 6,
            to: 7,
            verifier: verifier,
            createOld: (e) => v6.DatabaseAtV6(e),
            createNew: (e) => v7.DatabaseAtV7(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v6_to_v7.usersV6);
              b.insertAll(oldDb.groups, v6_to_v7.groupsV6);
            },
            validateItems: (newDb) async {
              expect(v6_to_v7.usersV7, await newDb.select(newDb.users).get());
              expect(v6_to_v7.groupsV7, await newDb.select(newDb.groups).get());
            },
          ));

  test(
      "default - migrate from v7 to v8",
      () => testWithDataIntegrity(
            from: 7,
            to: 8,
            verifier: verifier,
            createOld: (e) => v7.DatabaseAtV7(e),
            createNew: (e) => v8.DatabaseAtV8(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v7_to_v8.usersV7);
              b.insertAll(oldDb.groups, v7_to_v8.groupsV7);
              b.insertAll(oldDb.notes, v7_to_v8.notesV7);
            },
            validateItems: (newDb) async {
              expect(v7_to_v8.usersV8, await newDb.select(newDb.users).get());
              expect(v7_to_v8.groupsV8, await newDb.select(newDb.groups).get());
              expect(v7_to_v8.notesV8, await newDb.select(newDb.notes).get());
            },
          ));

  test(
      "default - migrate from v8 to v9",
      () => testWithDataIntegrity(
            from: 8,
            to: 9,
            verifier: verifier,
            createOld: (e) => v8.DatabaseAtV8(e),
            createNew: (e) => v9.DatabaseAtV9(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v8_to_v9.usersV8);
              b.insertAll(oldDb.groups, v8_to_v9.groupsV8);
              b.insertAll(oldDb.notes, v8_to_v9.notesV8);
            },
            validateItems: (newDb) async {
              expect(v8_to_v9.usersV9, await newDb.select(newDb.users).get());
              expect(v8_to_v9.groupsV9, await newDb.select(newDb.groups).get());
              expect(v8_to_v9.notesV9, await newDb.select(newDb.notes).get());
            },
          ));

  test(
      "default - migrate from v9 to v10",
      () => testWithDataIntegrity(
            from: 9,
            to: 10,
            verifier: verifier,
            createOld: (e) => v9.DatabaseAtV9(e),
            createNew: (e) => v10.DatabaseAtV10(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v9_to_v10.usersV9);
              b.insertAll(oldDb.groups, v9_to_v10.groupsV9);
              b.insertAll(oldDb.notes, v9_to_v10.notesV9);
            },
            validateItems: (newDb) async {
              expect(v9_to_v10.usersV10, await newDb.select(newDb.users).get());
              expect(
                  v9_to_v10.groupsV10, await newDb.select(newDb.groups).get());
              expect(v9_to_v10.notesV10, await newDb.select(newDb.notes).get());
            },
          ));

  test(
      "default - migrate from v10 to v11",
      () => testWithDataIntegrity(
            from: 10,
            to: 11,
            verifier: verifier,
            createOld: (e) => v10.DatabaseAtV10(e),
            createNew: (e) => v11.DatabaseAtV11(e),
            openTestedDatabase: (e) => Database(e),
            createItems: (b, oldDb) {
              b.insertAll(oldDb.users, v10_to_v11.usersV10);
              b.insertAll(oldDb.groups, v10_to_v11.groupsV10);
              b.insertAll(oldDb.notes, v10_to_v11.notesV10);
            },
            validateItems: (newDb) async {
              expect(
                  v10_to_v11.usersV11, await newDb.select(newDb.users).get());
              expect(
                  v10_to_v11.groupsV11, await newDb.select(newDb.groups).get());
              expect(
                  v10_to_v11.notesV11, await newDb.select(newDb.notes).get());
            },
          ));
}
