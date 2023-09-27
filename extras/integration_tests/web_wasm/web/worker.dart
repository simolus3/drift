import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen(setupAllDatabases: (db) {
    db.createFunction(
      functionName: 'database_host',
      function: (args) => 'worker',
      argumentCount: const AllowedArgumentCount(1),
    );
  });
}
