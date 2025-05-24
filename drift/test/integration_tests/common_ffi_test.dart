@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/connections/sqlite/native.dart';
import 'package:drift/connections/sqlite/sqlite3.dart';
import 'package:drift_testcases/tests.dart';
import 'package:path/path.dart' show join;
import 'package:sqlite3/sqlite3.dart' hide Database;
import 'package:test/test.dart';

import '../test_utils/database_vm.dart';

class DriftNativeExcecutor extends TestExecutor {
  static String fileName =
      'drift-native-tests-${DateTime.now().toIso8601String()}';
  final File file = File(join(Directory.systemTemp.path, fileName));

  @override
  bool get supportsNestedTransactions => true;

  @override
  bool get supportsReturning {
    final version = sqlite3.version;
    return version.versionNumber > 3035000;
  }

  @override
  DriftConnection createConnection() {
    return SqliteConnection.synchronous(open: () => sqlite3.open(file.path));
  }

  @override
  Future deleteData() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}

void main() {
  preferLocalSqlite3();

  runAllTests(DriftNativeExcecutor());

  test('can save and restore a database', () async {
    final mainFile =
        File(join(Directory.systemTemp.path, 'drift-save-and-restore-tests-1'));
    final createdForSwap =
        File(join(Directory.systemTemp.path, 'drift-save-and-restore-tests-2'));

    if (await mainFile.exists()) {
      await mainFile.delete();
    }
    if (await createdForSwap.exists()) {
      await createdForSwap.delete();
    }

    const nameInSwap = 'swap user';
    const nameInMain = 'main';

    // Prepare the file we're swapping in later
    final dbForSetup = Database(NativeDatabase.blocking(createdForSwap));
    await dbForSetup.into(dbForSetup.users).insert(
        UsersCompanion.insert(name: nameInSwap, birthDate: DateTime.now()));
    await dbForSetup.close();

    // Open the main file
    var db = Database(NativeDatabase.blocking(mainFile));
    await db.into(db.users).insert(
        UsersCompanion.insert(name: nameInMain, birthDate: DateTime.now()));
    await db.close();

    // Copy swap file to main file
    await mainFile.writeAsBytes(await createdForSwap.readAsBytes(),
        flush: true);

    // Re-open database
    db = Database(NativeDatabase.blocking(mainFile));
    final users = await db.select(db.users).get();

    expect(
      users.map((u) => u.name),
      allOf(contains(nameInSwap), isNot(contains(nameInMain))),
    );
  });
}
