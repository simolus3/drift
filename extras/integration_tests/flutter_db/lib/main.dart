import 'dart:io';

import 'package:tests/tests.dart';
import 'package:moor_flutter/moor_flutter.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:path/path.dart';

class SqfliteExecutor extends TestExecutor {
  @override
  QueryExecutor createExecutor() {
    return FlutterQueryExecutor.inDatabaseFolder(path: 'app.db');
  }

  @override
  Future deleteData() async {
    final folder = await getDatabasesPath();
    final file = File(join(folder, 'app.db'));

    if (await file.exists()) {
      await file.delete();
    }
  }
}

void main() {
  runAllTests(SqfliteExecutor());
}
