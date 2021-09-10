import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:path/path.dart' show join;
import 'package:sqlite3/sqlite3.dart';
import 'package:tests/tests.dart';

class VmExecutor extends TestExecutor {
  static String fileName = 'moor-vm-tests-${DateTime.now().toIso8601String()}';
  final File file = File(join(Directory.systemTemp.path, fileName));

  @override
  bool get supportsReturning {
    final version = sqlite3.version;
    return version.versionNumber > 3035000;
  }

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(VmDatabase(file));
  }

  @override
  Future deleteData() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}

void main() {
  runAllTests(VmExecutor());
}
