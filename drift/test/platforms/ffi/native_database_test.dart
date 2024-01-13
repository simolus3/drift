@TestOn('vm')
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/src/sqlite3/database.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../generated/todos.dart';
import '../../test_utils/database_vm.dart';

void main() {
  preferLocalSqlite3();

  group('implicit isolates', () {
    test('work with direct executors', () async {
      final file = File(d.path('test.db'));

      final db = TodoDb(NativeDatabase.createInBackground(file));
      await db.todosTable.select().get(); // Open the database
      await db.close();

      await d.file('test.db', anything).validate();
    });

    test('work with connections', () async {
      final file = File(d.path('test.db'));

      final db = TodoDb(NativeDatabase.createBackgroundConnection(file));
      await db.todosTable.select().get(); // Open the database
      await db.close();

      await d.file('test.db', anything).validate();
    });

    test('isolateSetup', () async {
      final receivePort = ReceivePort();
      final sendPort = receivePort.sendPort;
      final file = File(d.path('test.db'));

      const message = 'hi there';
      final db = TodoDb(
        NativeDatabase.createInBackground(
          file,
          isolateSetup: () => sendPort.send(message),
        ),
      );
      await db.todosTable.select().get(); // Open the database
      await db.close();

      await d.file('test.db', anything).validate();
      expect(receivePort, emits(message));
    });
  });

  group('NativeDatabase.opened', () {
    test('disposes the underlying database by default', () async {
      final underlying = sqlite3.openInMemory();
      final db = NativeDatabase.opened(underlying);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(() => underlying.execute('SELECT 1'), throwsStateError);
    });

    test('can avoid disposing the underlying instance', () async {
      final underlying = sqlite3.openInMemory();
      final db =
          NativeDatabase.opened(underlying, closeUnderlyingOnClose: false);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(() => underlying.execute('SELECT 1'), isNot(throwsA(anything)));
      underlying.dispose();
    });
  });

  group('checks for trailing statement content', () {
    late NativeDatabase db;

    setUp(() async {
      db = NativeDatabase.memory();
      await db.ensureOpen(_FakeExecutorUser());
    });

    tearDown(() => db.close());

    test('multiple statements are allowed for runCustom without args', () {
      return db.runCustom('SELECT 1; SELECT 2;');
    });

    test('throws for runCustom with args', () async {
      expect(db.runCustom('SELECT ?; SELECT ?;', [1, 2]), throwsArgumentError);
    });

    test('in runSelect', () async {
      expect(db.runSelect('SELECT ?; SELECT ?;', [1, 2]), throwsArgumentError);
    });

    test('in runBatched', () {
      expect(
        db.runBatched(BatchedStatements([
          'SELECT ?; SELECT ?;'
        ], [
          ArgumentsForBatchedStatement(0, []),
        ])),
        throwsArgumentError,
      );
    });
  });

  test('calls setup twice if first invocation fails', () async {
    const exception = 'exception';
    var count = 0;
    final db = NativeDatabase.memory(
      setup: expectAsync1(
        (_) {
          if (count++ == 0) {
            throw exception;
          }
        },
        count: 2,
      ),
    );

    await expectLater(db.ensureOpen(_FakeExecutorUser()), throwsA(exception));

    // Should also prevent subsequent open attempts
    await expectLater(db.ensureOpen(_FakeExecutorUser()), completes);
  });

  test('throwing in setup prevents the database from being opened', () async {
    const exception = 'exception';
    final db = NativeDatabase.memory(setup: (_) => throw exception);

    await expectLater(db.ensureOpen(_FakeExecutorUser()), throwsA(exception));

    // Should also prevent subsequent open attempts
    await expectLater(db.ensureOpen(_FakeExecutorUser()), throwsA(exception));
  });

  test('disposes statements directly if cache is disabled', () async {
    final underlying = sqlite3.openInMemory();
    final db =
        NativeDatabase.opened(underlying, cachePreparedStatements: false);
    addTearDown(db.close);

    await db.ensureOpen(_FakeExecutorUser());
    await db.runCustom('CREATE TABLE foo (bar INTEGER);');
    await db.runCustom('UPDATE foo SET bar = 1');
    expect(underlying.activeStatementCount, isZero);
  });

  test('disposes statements eventually if cache is enabled', () async {
    final underlying = sqlite3.openInMemory();
    addTearDown(underlying.dispose);
    final db = NativeDatabase.opened(
      underlying,
      cachePreparedStatements: true,
      closeUnderlyingOnClose: false,
    );

    await db.ensureOpen(_FakeExecutorUser());
    expect(underlying.activeStatementCount, isZero);

    for (var i = 1; i <= PreparedStatementsCache.defaultSize; i++) {
      await db.runSelect('SELECT $i', []);
      expect(underlying.activeStatementCount, i);
    }

    for (var i = 0; i < PreparedStatementsCache.defaultSize; i++) {
      // This will evict old statements, so the amount of active statements
      // should not change.
      await db.runSelect('SELECT $i AS "new"', []);
      expect(
          underlying.activeStatementCount, PreparedStatementsCache.defaultSize);
    }

    await db.close();
    expect(underlying.activeStatementCount, isZero);
  });

  group('can disable migrations', () {
    Future<void> runTest(QueryExecutor executor) async {
      final db = TodoDb(executor);
      db.migration = MigrationStrategy(
        onCreate: (_) => fail('should not call onCreate'),
        onUpgrade: (_, __, ___) => fail('should not call onUpgrade'),
        beforeOpen: expectAsync1((details) async {}),
      );

      addTearDown(db.close);
      await db.customSelect('select 1').get(); // open database
    }

    test(
      'with native database',
      () => runTest(NativeDatabase(
        File(d.path('test.db')),
        enableMigrations: false,
      )),
    );

    test(
      'createInBackground',
      () => runTest(NativeDatabase.createInBackground(
        File(d.path('test.db')),
        enableMigrations: false,
      )),
    );

    test(
      'createBackgroundConnection',
      () => runTest(NativeDatabase.createBackgroundConnection(
        File(d.path('test.db')),
        enableMigrations: false,
      )),
    );

    test(
      'opened',
      () => runTest(NativeDatabase.opened(
        sqlite3.openInMemory(),
        enableMigrations: false,
        closeUnderlyingOnClose: true,
      )),
    );
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

extension on Database {
  /// Counts the amount of statements currently prepared in this database by
  /// invoking `sqlite3_next_stmt` repeatedly.
  int get activeStatementCount {
    final library = open.openSqlite();
    final nextStmt = library.lookupFunction<Pointer Function(Pointer, Pointer),
        Pointer Function(Pointer, Pointer)>(
      'sqlite3_next_stmt',
    );

    Pointer currentStatement;
    var count = 0;

    for (currentStatement = nextStmt(handle.cast(), nullptr);
        currentStatement.address != 0;
        currentStatement = nextStmt(handle.cast(), currentStatement)) {
      count++;
    }

    return count;
  }
}
