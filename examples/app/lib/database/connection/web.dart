import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/web.dart';
import 'package:drift/wasm.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/wasm.dart';

const _useWorker = true;

/// Obtains a database connection for running drift on the web.
DatabaseConnection connect({bool isInWebWorker = false}) {
  if (_useWorker && !isInWebWorker) {
    final worker = SharedWorker('shared_worker.dart.js');
    return remote(worker.port!.channel());
  } else {
    return DatabaseConnection.delayed(Future.sync(() async {
      // We're using the experimental wasm support in Drift because this gives
      // us a recent sqlite3 version with fts5 support.
      // This is still experimental, so consider using the approach described in
      // https://drift.simonbinder.eu/web/ instead.

      final response = await http.get(Uri.parse('sqlite3.wasm'));
      final fs = await IndexedDbFileSystem.open(dbName: 'my_app');
      final sqlite3 = await WasmSqlite3.load(
        response.bodyBytes,
        SqliteEnvironment(fileSystem: fs),
      );

      final databaseImpl = WasmDatabase(sqlite3: sqlite3, path: 'app.db');
      return DatabaseConnection.fromExecutor(databaseImpl);
    }));
  }
}
