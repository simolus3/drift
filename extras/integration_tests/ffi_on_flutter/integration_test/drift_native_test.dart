import 'dart:io';

import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:drift_testcases/tests.dart';
import 'package:flutter/services.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';

class FfiExecutor extends TestExecutor {
  final String dbPath;

  FfiExecutor(this.dbPath);

  @override
  bool get supportsNestedTransactions => true;

  @override
  bool get supportsReturning => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection(NativeDatabase(File(join(dbPath, 'app_ffi.db'))));
  }

  @override
  Future deleteData() async {
    final file = File(join(dbPath, 'app_ffi.db'));
    if (await file.exists()) {
      await file.delete();
    }
  }
}

Future<String> get _testDbDirectory async {
  final dbDirectory =
      await Directory.systemTemp.createTemp('drift-ffi-flutter');
  return dbDirectory.path;
}

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final dbPath = await _testDbDirectory;
  runAllTests(FfiExecutor(dbPath));

  test('supports the rtree module', () {
    final db = raw.sqlite3.openInMemory();

    db.execute('''
      CREATE VIRTUAL TABLE demo_index USING rtree(
        id,              -- Integer primary key
        minX, maxX,      -- Minimum and maximum X coordinate
        minY, maxY       -- Minimum and maximum Y coordinate
      );

      INSERT INTO demo_index VALUES(
        1,                   -- Primary key -- SQLite.org headquarters
       -80.7749, -80.7747,  -- Longitude range
       35.3776, 35.3778     -- Latitude range
      );

      INSERT INTO demo_index VALUES(
        2,                   -- NC 12th Congressional District in 2010
        -81.0, -79.6,
        35.0, 36.2
      );
    ''');

    final stmt = db.prepare('''
      SELECT id FROM demo_index
        WHERE minX>=-81.08 AND maxX<=-80.58
        AND minY>=35.00  AND maxY<=35.44;
    ''');

    expect(stmt.select().single['id'], 1);

    db.dispose();
  });

  test('isolates integration test', () async {
    // This test exists to verify that our communication protocol works when we
    // can only send primitive objects over isolates.
    final isolate = await DriftIsolate.spawn(_openInBackground);
    final connection = await isolate.connect();

    final db = Database(connection);

    await db.transaction(() async {
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      await db.into(db.users).insert(
          UsersCompanion.insert(name: 'Name', birthDate: DateTime.now()));
    });

    await db.mostPopularUsers(13).get();

    await db.close();
    await isolate.shutdownAll();
  });

  test('can use database path in background isolate', () async {
    final token = RootIsolateToken.instance!;
    final isolate = await DriftIsolate.spawn(() {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);

      return LazyDatabase(() async {
        final path = await _testDbDirectory;
        final file = File(join(path, 'background.db'));

        return NativeDatabase(file);
      });
    });

    final db = Database(await isolate.connect());
    await db.customSelect('SELECT 1').getSingle();
  });
}

DatabaseConnection _openInBackground() {
  return DatabaseConnection(NativeDatabase.memory());
}
