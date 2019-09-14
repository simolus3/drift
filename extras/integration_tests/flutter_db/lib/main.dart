import 'dart:io';

import 'package:flutter/services.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:tests/tests.dart';
import 'package:test/test.dart';
import 'package:moor_flutter/moor_flutter.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:path/path.dart';

class SqfliteExecutor extends TestExecutor {
  @override
  QueryExecutor createExecutor() {
    return FlutterQueryExecutor.inDatabaseFolder(
      path: 'app.db',
      singleInstance: false,
    );
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

class FfiExecutor extends TestExecutor {
  @override
  QueryExecutor createExecutor() {
    return VmDatabase(File('app_ffi.db'));
  }

  @override
  Future deleteData() async {
    final file = File('app_ffi.db');
    if (await file.exists()) {
      await file.delete();
    }
  }
}

void main() {
  runAllTests(SqfliteExecutor());
  runAllTests(FfiExecutor());

  // Additional integration test for flutter: Test loading a database from asset
  test('can load a database from asset', () async {
    var didCallCreator = false;
    final executor = FlutterQueryExecutor.inDatabaseFolder(
      path: 'app_from_asset.db',
      singleInstance: true,
      creator: (file) async {
        final content = await rootBundle.load('test_asset.db');
        await file.writeAsBytes(content.buffer.asUint8List());
        didCallCreator = true;
      },
    );
    final database = Database(executor);
    await database.getUserById(0); // load user so that the db is opened

    expect(didCallCreator, isTrue);
  });
}
