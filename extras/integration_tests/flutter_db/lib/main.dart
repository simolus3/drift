import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runAllTests(SqfliteExecutor());

  // Additional integration test for flutter: Test loading a database from asset
  test('can load a database from asset', () async {
    const dbNameInDevice = 'app_from_asset.db';

    final folder = await getDatabasesPath();
    final file = File(join(folder, dbNameInDevice));

    if (await file.exists()) {
      await file.delete();
    }


    var didCallCreator = false;
    final executor = FlutterQueryExecutor.inDatabaseFolder(
      path: dbNameInDevice,
      singleInstance: true,
      creator: (file) async {
        final content = await rootBundle.load('test_asset.db');
        await file.writeAsBytes(content.buffer.asUint8List());
        didCallCreator = true;
      },
    );
    final database = Database(executor);
    await database.executor.ensureOpen();

    expect(didCallCreator, isTrue);
  });
}
