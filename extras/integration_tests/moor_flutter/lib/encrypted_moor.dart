import 'dart:io';

import 'package:encrypted_moor/encrypted_moor.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:tests/tests.dart';

class EncryptedTestExecutor extends TestExecutor {
  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(
      EncryptedExecutor.inDatabaseFolder(
        path: 'appenc.db',
        singleInstance: false,
        password: 'passw0rd',
        logStatements: true,
      ),
    );
  }

  @override
  Future deleteData() async {
    final folder = await getDatabasesPath();
    final file = File(join(folder, 'appenc.db'));

    if (await file.exists()) {
      await file.delete();
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runAllTests(EncryptedTestExecutor());
}
