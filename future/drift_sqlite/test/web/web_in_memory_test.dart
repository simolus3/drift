@TestOn('browser')
library;

import 'package:drift3_preview/drift.dart';
import 'package:drift3_testcases/suite/suite.dart';
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

  runAllTests(_WebInMemoryExecutor(() => sqlite));
}

final class _WebInMemoryExecutor extends TestExecutor {
  final WasmSqlite3 Function() sqlite;

  var _deleteCounter = 0;

  _WebInMemoryExecutor(this.sqlite);

  @override
  DriftConnection createConnection() {
    return DriftConnection(
      dialect: SqliteDialect.new,
      openConnection: () async =>
          SqliteConnection(sqlite().open('/tmp/$_deleteCounter/test.db')),
    );
  }

  @override
  Future<dynamic> deleteData() async {
    _deleteCounter++;
  }
}
