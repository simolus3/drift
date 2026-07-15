import 'package:drift_sqlite/web.dart';
import 'package:sqlite3_web/sqlite3_web.dart';

/// This Dart program is the entrypoint of a web worker that will be compiled to
/// JavaScript by running `build_runner build`. The resulting JavaScript file
/// (`shared_worker.dart.js`) is part of the build result and will be shipped
/// with the rest of the application when running or building a Flutter web app.
void main() {
  return WebSqlite.workerEntrypoint(
      controller: WasmDatabase.driftDatabaseController());
}
