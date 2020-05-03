import 'dart:io';

import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:moor_ffi/moor_ffi.dart';
import 'package:test/test.dart';
import 'package:tests/tests.dart';
import 'package:moor/isolate.dart';
import 'package:moor_flutter/moor_flutter.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:path/path.dart';

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
