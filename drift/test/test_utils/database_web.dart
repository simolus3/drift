import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/wasm.dart';
import 'package:test/scaffolding.dart';

Version get sqlite3Version {
  return Version('3.38.2', 'stub', 3038200);
}

Future<WasmSqlite3>? _loadedSqlite3;

Future<WasmSqlite3> get sqlite3 {
  return _loadedSqlite3 ??= Future.sync(() async {
    final channel = spawnHybridUri('/test/test_utils/sqlite_server.dart');
    final port = await channel.stream.first as int;

    final response =
        await http.get(Uri.parse('http://localhost:$port/sqlite3.wasm'));
    return WasmSqlite3.load(response.bodyBytes);
  });
}

DatabaseConnection testInMemoryDatabase() {
  return DatabaseConnection.fromExecutor(LazyDatabase(() async {
    final sqlite = await sqlite3;
    return WasmDatabase.inMemory(sqlite);
  }));
}
