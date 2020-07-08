import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:tests/tests.dart';

import 'package:path/path.dart' show join;

class VmExecutor extends TestExecutor {
  static String fileName = 'moor-vm-tests-${DateTime.now().toIso8601String()}';
  final File file = File(join(Directory.systemTemp.path, fileName));

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
