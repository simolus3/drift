import 'dart:io';

import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:moor_ffi/moor_ffi.dart';
import 'package:tests/tests.dart';
import 'package:moor_flutter/moor_flutter.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:path/path.dart';

class FfiExecutor extends TestExecutor {
  final String dbPath;

  FfiExecutor(this.dbPath);

  @override
  QueryExecutor createExecutor() {
    return VmDatabase(File(join(dbPath, 'app_ffi.db')));
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
}
