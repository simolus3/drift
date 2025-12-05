@TestOn('browser')
library;

import 'package:drift/drift.dart';
import 'package:drift/src/web/wasm_setup/indexeddb_to_opfs.dart';
import 'package:drift/src/web/wasm_setup/shared.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';
import 'package:test/test.dart';

import '../../test_utils/database_web.dart' as loader;

void main() {
  late WasmSqlite3 sqlite3;

  setUpAll(() async {
    final sqlite = sqlite3 = await loader.sqlite3;
    sqlite.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  });

  group('WasmDatabase.opened', () {
    test('disposes the underlying database by default', () async {
      final underlying = sqlite3.openInMemory();
      final db = WasmDatabase.opened(underlying);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(() => underlying.execute('SELECT 1'), throwsStateError);
    });

    test('can avoid disposing the underlying instance', () async {
      final underlying = sqlite3.openInMemory();
      final db = WasmDatabase.opened(underlying, closeUnderlyingOnClose: false);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(() => underlying.execute('SELECT 1'), isNot(throwsA(anything)));
      underlying.dispose();
    });
  });

  test('moveIndexedDbDatabaseToOpfs', () async {
    final indexedDb = await IndexedDbFileSystem.open(dbName: 'test_move');
    sqlite3.registerVirtualFileSystem(indexedDb);
    final db = sqlite3.open('/database', vfs: indexedDb.name);
    db.execute('CREATE TABLE foo (bar TEXT);');
    db.dispose();
    await indexedDb.close();

    await moveIndexedDBDatabaseToOpfs('test_move');

    expect(await opfsDatabases(), ['test_move']);
    expect(await checkIndexedDbExists('test_move'), isFalse);
  });
}

class _FakeExecutorUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return Future.value();
  }

  @override
  int get schemaVersion => 1;
}
