import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift/web/worker.dart';
import 'package:http/http.dart' as http;
import 'package:fetch_client/fetch_client.dart' as http;
import 'package:sqlite3/wasm.dart';

const _useWorker = true;

/// Obtains a database connection for running drift on the web.
DatabaseConnection connect({bool isInWebWorker = false}) {
  if (_useWorker && !isInWebWorker) {
    return DatabaseConnection.delayed(
        connectToDriftWorker('shared_worker.dart.js', shared: true));
  } else {
    return DatabaseConnection.delayed(
      // We're using the experimental wasm support in Drift because this gives
      // us a recent sqlite3 version with fts5 support.
      // This is still experimental, so consider using the approach described in
      // https://drift.simonbinder.eu/web/ instead.
      http.runWithClient(
        () async {
          final response = await http.get(Uri.parse('sqlite3.wasm'));
          final fs = await IndexedDbFileSystem.open(dbName: 'my_app');
          final sqlite3 = await WasmSqlite3.load(
            response.bodyBytes,
            SqliteEnvironment(fileSystem: fs),
          );

          final databaseImpl = WasmDatabase(sqlite3: sqlite3, path: 'app.db');
          return DatabaseConnection(databaseImpl);
        },
        // Dart's wrapper around XMLHttpRequests doesn't work in Safari web
        // workers: https://github.com/dart-lang/sdk/issues/51918
        () => isInWebWorker ? http.FetchClient() : http.Client(),
      ),
    );
  }
}

Future<void> validateDatabaseSchema(GeneratedDatabase database) async {
  // Unfortunately, validating database schemas only works for native platforms
  // right now.
  // As we also have migration tests (see the `Testing migrations` section in
  // the readme of this example), this is not a huge issue.
}
