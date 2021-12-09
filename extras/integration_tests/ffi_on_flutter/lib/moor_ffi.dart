import 'dart:io';

import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:moor/ffi.dart';
import 'package:moor/isolate.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';
import 'package:tests/tests.dart';

class FfiExecutor extends TestExecutor {
  final String dbPath;

  FfiExecutor(this.dbPath);

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(
        VmDatabase(File(join(dbPath, 'app_ffi.db'))));
  }

  @override
  Future deleteData() async {
    final file = File(join(dbPath, 'app_ffi.db'));
    if (await file.exists()) {
      await file.delete();
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbPath = await getDatabasesPath();
  Directory(dbPath).createSync(recursive: true);
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
    final isolate = await MoorIsolate.spawn(_openInBackground);
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
}

DatabaseConnection _openInBackground() {
  return DatabaseConnection.fromExecutor(VmDatabase.memory());
}
