import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift/web/worker.dart';
import 'package:sqlite3/wasm.dart';

void main() {
  driftWorkerMain(() {
    return LazyDatabase(() async {
      // You can use a different OPFS path here is you need more than one
      // persisted database in your app.
      final fileSystem = await OpfsFileSystem.loadFromStorage('my_database');

      final sqlite3 = await WasmSqlite3.loadFromUrl(
        // Uri where you're hosting the wasm bundle for sqlite3
        Uri.parse('/sqlite3.wasm'),
        environment: SqliteEnvironment(fileSystem: fileSystem),
      );

      // The path here should always be `database` since that is the only file
      // persisted by the OPFS file system.
      return WasmDatabase(sqlite3: sqlite3, path: 'database');
    });
  });
}
