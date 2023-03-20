import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/wasm.dart';

QueryExecutor connect() {
  return LazyDatabase(() async {
    // Create virtual filesystem for sqlite3 implemented over blobs stored in an
    // IndexedDB database (named `my_app` here).
    final fs = await IndexedDbFileSystem.open(dbName: 'my_app');

    // Load wasm bundle for sqlite3
    final response = await http.get(Uri.parse('sqlite3.wasm'));
    final sqlite3 = await WasmSqlite3.load(
      response.bodyBytes,
      SqliteEnvironment(fileSystem: fs),
    );

    // Then, open a database:
    return WasmDatabase(sqlite3: sqlite3, path: '/app.db');
  });
}
