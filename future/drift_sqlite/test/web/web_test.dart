@TestOn('browser')
library;

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/web.dart';
import 'package:sqlite3_web/sqlite3_web.dart';
import 'package:test/test.dart';

import '../connection_testcases.dart';
import 'load_wasm_url.dart';

void main() {
  late Uri sqliteWasmUri;

  setUpAll(() async {
    sqliteWasmUri = await loadWasmUrl();
  });

  var dbCounter = 0;
  declareConnectionTests(() async {
    final sqlite = WebSqlite.open(
      workers: WorkerConnector.unsupported(),
      controller: DriftDatabaseController(),
      wasmModule: sqliteWasmUri.toString(),
    );
    final db = await sqlite.connect('db-${dbCounter++}', .inMemoryLocal);
    return OpenedDriftConnection(
      WasmDatabase.wrapDatabase(db),
      InMemoryStreamQueryStore(),
    );
  });
}
