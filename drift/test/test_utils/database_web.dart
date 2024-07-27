import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';
import 'package:test/scaffolding.dart';

Version get sqlite3Version {
  // We can't get the version synchronously since we need to load a wasm module.
  // So it's hardcoded here and needs to be kept in sync with
  // `extras/assets/sqlite3.wasm`.
  return Version('3.46.0', 'stub', 3046000);
}

Future<WasmSqlite3>? _loadedSqlite3;

Future<WasmSqlite3> get sqlite3 {
  return _loadedSqlite3 ??= Future.sync(() async {
    final channel = spawnHybridUri('/test/test_utils/sqlite_server.dart');
    final port = (await channel.stream.first as num).toInt();

    final sqlite = await WasmSqlite3.loadFromUrl(
        Uri.parse('http://localhost:$port/sqlite3.wasm'));
    sqlite.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
    channel.sink.close();

    return sqlite;
  });
}

DatabaseConnection testInMemoryDatabase() {
  return DatabaseConnection(LazyDatabase(() async {
    final sqlite = await sqlite3;
    return WasmDatabase.inMemory(sqlite);
  }));
}
