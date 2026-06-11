export 'src/connection/web/worker.dart';

import 'package:drift3/drift.dart';
import 'package:sqlite3_web/sqlite3_web.dart';

import 'src/connection/web/session.dart';
import 'src/connection/web/worker.dart';

/// Utilities for opening databases based on a version of SQLite that has been
/// compiled to WebAssembly.
final class WasmDatabase {
  /// The [WebSqlite] helper used to open databases in workers.
  final WebSqlite webSqlite;

  /// Creates a [WasmDatabase] wrapper from the inner [WebSqlite] instance.
  ///
  /// Alternatively, [withWorker] is probably easier to use.
  WasmDatabase(this.webSqlite);

  /// Creates a [WasmDatabase] from the `sqlite3.wasm` and `drift_worker.js`
  /// URIs.
  static WasmDatabase withWorker({
    required String databaseWorker,
    required String sqlite3Uri,
  }) {
    final sqlite = WebSqlite.open(
      workers: WorkerConnector.defaultWorkers(databaseWorker),
      wasmModule: sqlite3Uri,
      controller: DriftDatabaseController(),
    );
    return WasmDatabase(sqlite);
  }

  /// Opens a database identified by its name with default options suitable for
  /// the current browser.
  Future<WasmDatabaseResult> open(String name) async {
    final result = await webSqlite.connectToRecommended(name);

    return WasmDatabaseResult._(WebSession(result.database), result);
  }

  /// Wraps a [Database] from the `sqlite3_web` package as a [DriftSession].
  ///
  /// This can be used for custom database instances. Using [open] is a suitable
  /// default though.
  static DriftSession wrapDatabase(Database database) {
    return WebSession(database);
  }
}

/// The result of opening a WASM database with default options.
final class WasmDatabaseResult {
  /// The drift database connection to return from the [DriftConnection]
  /// callback to use the database.
  final DriftSession session;

  /// Results with information about available browser features.
  final ConnectToRecommendedResult result;

  WasmDatabaseResult._(this.session, this.result);
}
