import 'dart:io';

import 'package:moor_ffi/moor_ffi.dart';
import 'package:tests/tests.dart';

import 'package:path/path.dart' show join;

class VmExecutor extends TestExecutor {
  static String fileName = 'moor-vm-tests-${DateTime.now().toIso8601String()}';
  final file = File(join(Directory.systemTemp.path, fileName));

  @override
  QueryExecutor createExecutor() {
    return VmDatabase(file);
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
