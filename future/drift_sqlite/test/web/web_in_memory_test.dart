@TestOn('browser')
library;

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:sqlite3/wasm.dart';
import 'package:test/test.dart';

import '../connection_testcases.dart';
import 'load_wasm_url.dart';

void main() {
  late final WasmSqlite3 sqlite;

  setUpAll(() async {
    sqlite = await WasmSqlite3.loadFromUrl(await loadWasmUrl());
    sqlite.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  });

  declareConnectionTests(() async {
    return OpenedDriftConnection(
      SqliteConnection(sqlite.openInMemory()),
      InMemoryStreamQueryStore(),
    );
  });
}
