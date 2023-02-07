import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<File> get databaseFile async {
  // We use `path_provider` to find a suitable path to store our data in.
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDir.path, 'todos.db');
  return File(dbPath);
}

/// Obtains a database connection for running drift in a Dart VM.
DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future(() async {
    return NativeDatabase.createBackgroundConnection(await databaseFile);
  }));
}
