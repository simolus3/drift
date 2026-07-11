import 'package:drift_sqlite/web.dart';
import 'package:sqlite3_web/sqlite3_web.dart';

void main() {
  WebSqlite.workerEntrypoint(
    controller: WasmDatabase.driftDatabaseController(),
  );
}
