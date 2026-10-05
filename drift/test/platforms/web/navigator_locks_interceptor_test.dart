@TestOn('browser')
library;

import 'package:drift/drift.dart';
import 'package:drift/src/web/wasm_setup/navigator_locks_interceptor.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/database_web.dart' as loader;

void main() {
  late WasmSqlite3 sqlite3;

  setUpAll(() async {
    final sqlite = sqlite3 = await loader.sqlite3;
    sqlite.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  });

  late CommonDatabase rawDb;

  setUp(() => rawDb = sqlite3.openInMemory());
  tearDown(() => rawDb.close());

  QueryExecutor connect() {
    return NavigatorLocksExecutor(
      WasmDatabase.opened(rawDb, closeUnderlyingOnClose: false),
      'navigator-locks',
    );
  }

  test('smoke test', () async {
    final db = TodoDb(connect());
    addTearDown(db.close);
    await db.todosTable.insertOne(
      TodosTableCompanion.insert(content: 'test content'),
    );

    expect(await db.todosTable.all().get(), isNotEmpty);
  });

  test('nested transactions complete the outer transaction', () async {
    // Regression test for https://github.com/simolus3/drift/issues/3870:
    // the nested transaction used to complete the shared navigator-lock
    // completer, so the outer commit failed and its rollback hung forever.
    final db = TodoDb(connect());
    addTearDown(db.close);

    await db.transaction(() async {
      await db.transaction(() async {});
    });
  });

  test('nested transaction with rollback rolls the outer one back', () async {
    final db = TodoDb(connect());
    addTearDown(db.close);

    final outer = db.transaction<void>(() async {
      await db
          .transaction(() async {
            await db.todosTable.insertOne(
              TodosTableCompanion.insert(content: 'nested'),
            );
          })
          .then((_) => throw Exception('rollback after nested commit'));
    });
    // The nested commit succeeded, but the outer transaction rolls back.
    await expectLater(outer, throwsA(isA<Exception>()));

    expect(await db.todosTable.all().get(), isEmpty);
  });

  test("can't have concurrent transactions", () async {
    var concurrentTransactions = 0;
    var totalTransactions = 0;

    Future<void> handleTransaction() async {
      concurrentTransactions++;
      totalTransactions++;

      try {
        expect(concurrentTransactions, 1);
        await pumpEventQueue();
        expect(concurrentTransactions, 1);
      } finally {
        concurrentTransactions--;
      }
    }

    final a = TodoDb(connect());
    final b = TodoDb(connect());
    addTearDown(a.close);
    addTearDown(b.close);

    final futures = <Future<void>>[];

    for (var i = 0; i < 10; i++) {
      futures.add(a.transaction(handleTransaction));
      futures.add(b.transaction(handleTransaction));
    }

    await futures.wait;
    expect(totalTransactions, 20);
  });

  test("can't have concurrent exclusive", () async {
    var concurrentTransactions = 0;
    var totalTransactions = 0;

    Future<void> handleExlusive() async {
      concurrentTransactions++;
      totalTransactions++;

      try {
        expect(concurrentTransactions, 1);
        await pumpEventQueue();
        expect(concurrentTransactions, 1);
      } finally {
        concurrentTransactions--;
      }
    }

    final a = TodoDb(connect());
    final b = TodoDb(connect());
    addTearDown(a.close);
    addTearDown(b.close);

    final futures = <Future<void>>[];

    for (var i = 0; i < 10; i++) {
      futures.add(a.exclusively(handleExlusive));
      futures.add(b.exclusively(handleExlusive));
    }

    await futures.wait;
    expect(totalTransactions, 20);
  });
}
