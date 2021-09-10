import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:moor_flutter/moor_flutter.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:test/test.dart';
import 'package:tests/tests.dart';

class SqfliteExecutor extends TestExecutor {
  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(
      FlutterQueryExecutor.inDatabaseFolder(
        path: 'app.db',
        singleInstance: false,
      ),
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
    final databasesPath = await getDatabasesPath();
    final dbFile = File(join(databasesPath, 'app_from_asset.db'));
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    var didCallCreator = false;
    final executor = FlutterQueryExecutor(
      path: dbFile.path,
      singleInstance: true,
      creator: (file) async {
        final content = await rootBundle.load('test_asset.db');
        await file.writeAsBytes(content.buffer.asUint8List());
        didCallCreator = true;
      },
    );
    final database = Database.executor(executor);
    await database.executor.ensureOpen(database);

    expect(didCallCreator, isTrue);
  });
}
