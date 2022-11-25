import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Obtains a database connection for running drift in a Dart VM.
DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future(() async {
    // Background isolates can't use platform channels, so let's use
    // `path_provider` in the main isolate and just send the result containing
    // the path over to the background isolate.

    // We use `path_provider` to find a suitable path to store our data in.
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, 'todos.db');

    return NativeDatabase.createBackgroundConnection(File(dbPath));
  }));
}
