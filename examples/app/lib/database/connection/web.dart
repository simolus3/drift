import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift/web/worker.dart';
import 'package:sqlite3/wasm.dart';

const _useWorker = true;

/// Obtains a database connection for running drift on the web.
DatabaseConnection connect({bool isInWebWorker = false}) {
  if (_useWorker && !isInWebWorker) {
    return DatabaseConnection.delayed(connectToDriftWorker(
        'shared_worker.dart.js',
        mode: DriftWorkerMode.shared));
  } else {
    return DatabaseConnection.delayed(
      Future.sync(() async {
        final fs = await IndexedDbFileSystem.open(dbName: 'my_app');
        final sqlite3 = await WasmSqlite3.loadFromUrl(
          Uri.parse('sqlite3.wasm'),
          environment: SqliteEnvironment(fileSystem: fs),
        );

        final databaseImpl = WasmDatabase(sqlite3: sqlite3, path: 'app.db');
        return DatabaseConnection(databaseImpl);
      }),
    );
  }
}

Future<void> validateDatabaseSchema(GeneratedDatabase database) async {
  // Unfortunately, validating database schemas only works for native platforms
  // right now.
  // As we also have migration tests (see the `Testing migrations` section in
  // the readme of this example), this is not a huge issue.
}
