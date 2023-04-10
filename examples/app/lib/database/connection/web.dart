import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift/web/worker.dart';
import 'package:riverpod/riverpod.dart';
import 'package:sqlite3/wasm.dart';

import 'status.dart';

const _workerJs = 'shared_worker.dart.js';
final _sqlite3Wasm = Uri.parse('sqlite3.wasm');

/// Obtains a database connection for running drift on the web.
DatabaseConnection connect(Ref ref) {
  return DatabaseConnection.delayed(Future.sync(() async {
    final compatibility = await checkForDriftWebCompatibility(_workerJs);

    // This app uses OPFS and both shared and dedicated workers, so if any of
    // that isn't supported...
    if (!compatibility.dedicatedWorkersSupported ||
        !compatibility.sharedWorkersSupported ||
        compatibility.opfsSupported != true) {
      ref.read(databaseStatusProvider.notifier).state =
          'Unfortunately, this browser does not support storing sqlite3 '
          'databases. Consider using Chrome, Firefox or a Safari Technology '
          'Preview';

      // We'll fall back to an in-memory database that isn't persisted and
      // show a warning to the user.
      final sqlite3 = await WasmSqlite3.loadFromUrl(_sqlite3Wasm);
      return DatabaseConnection(WasmDatabase.inMemory(sqlite3));
    } else {
      // Everything we need is supported on this browser, so we can use a
      // shared worker setup.
      return await connectToDriftWorker(_workerJs,
          mode: DriftWorkerMode.dedicatedInShared);
    }
  }));
}

Future<QueryExecutor> connectInWorker() async {
  // Using an OpfsFileSystem is the recommended approach, but it is not
  // available on stable Safari versions yet. The IndexedDbFileSystem
  // implementation is an alternative for those browsers.
  final fs = await OpfsFileSystem.loadFromStorage('my_app');
  // final fs = await IndexedDbFileSystem.open(dbName: 'my_app');
  final sqlite3 = await WasmSqlite3.loadFromUrl(
    Uri.parse('sqlite3.wasm'),
    environment: SqliteEnvironment(fileSystem: fs),
  );

  // Note that the path needs to be `database` when using an OpfsFileSystem
  final databaseImpl = WasmDatabase(sqlite3: sqlite3, path: 'database');
  return DatabaseConnection(databaseImpl);
}

Future<void> validateDatabaseSchema(GeneratedDatabase database) async {
  // Unfortunately, validating database schemas only works for native platforms
  // right now.
  // As we also have migration tests (see the `Testing migrations` section in
  // the readme of this example), this is not a huge issue.
}
