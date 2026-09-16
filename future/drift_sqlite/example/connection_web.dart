import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/web.dart';
import 'package:sqlite3_web/sqlite3_web.dart';

Future<DriftSession> openConnection() async {
  final web = WebSqlite.open(
    wasmModule: 'https://cdn.jsdelivr.net/npm/sqlite3-web/assets/sqlite3.wasm',
    // For a real setup, consider using a database with web workers for better
    // performance and multi-tab support: https://drift.simonbinder.eu/platforms/web/
    workers: .defaultWorkers(''),
    controller: WasmDatabase.driftDatabaseController(),
  );

  final rawDb = await web.connect('memory', .inMemoryLocal);
  return WasmDatabase.wrapDatabase(rawDb);
}
