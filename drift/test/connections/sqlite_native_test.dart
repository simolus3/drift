@TestOn('vm')
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:drift/connections/sqlite/native.dart';
import 'package:drift/drift.dart';
import 'package:drift/src/connections/sqlite3/connection.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../generated/todos.dart';
import '../test_utils/database_vm.dart';

void main() {
  preferLocalSqlite3();

  group('implicit isolates', () {
    test('work with direct executors', () async {
      final file = File(d.path('test.db'));

      final db = TodoDb(NativeDatabase.createInBackground(file));
      await db.initialize();
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
      await db.initialize();
      await db.close();

      await d.file('test.db', anything).validate();
      expect(receivePort, emits(message));
    });

    test('read pool cannot be negative', () {
      final file = File(d.path('test.db'));

      expect(() => NativeDatabase.createInBackground(file, readPool: -4),
          throwsRangeError);
    });

    test('read pool', () async {
      final file = File(d.path('test.db'));

      final db = TodoDb(
        NativeDatabase.createInBackground(
          file,
          setup: (db) {
            var counter = 0;

            db.createFunction(
                functionName: 'inc_counter', function: (args) => counter++);
          },
          readPool: 10,
        ),
      );

      final group = FutureGroup<void>();
      for (var i = 0; i < 100; i++) {
        final future = db
            .customSelect('SELECT inc_counter() AS r;')
            .getSingle()
            .then((row) {
          final counter = row.readWithType(BuiltinDriftType.int, 'r');
          expect(counter < 20, isTrue,
              reason: 'should distribute somewhat evenly, counter is $counter');
        });

        group.add(future);
      }

      group.close();
      await group.future;
      await db.close();
    });
  });

  group('NativeDatabase.opened', () {
    test('disposes the underlying database by default', () async {
      final underlying = sqlite3.openInMemory();
      final (session, _) = await NativeDatabase.opened(underlying).open();

      await session.close();
      expect(() => underlying.execute('SELECT 1'), throwsStateError);
    });

    test('can avoid disposing the underlying instance', () async {
      final underlying = sqlite3.openInMemory();
      final (session, _) =
          await NativeDatabase.opened(underlying, closeUnderlyingOnClose: false)
              .open();

      await session.close();
      expect(() => underlying.execute('SELECT 1'), isNot(throwsA(anything)));
      underlying.dispose();
    });
  });

  group('checks for trailing statement content', () {
    late DriftSession db;

    setUp(() async {
      final impl = await NativeDatabase.memory().open();
      db = impl.$1;
    });

    tearDown(() => db.close());

    test('multiple statements are allowed for runCustom without args',
        () async {
      await db.execute(StatementInfo.fromText('SELECT 1; SELECT 2;'));
    });

    test('throws for runCustom with args', () async {
      expect(
          db.execute(StatementInfo.fromText(
            'SELECT ?; SELECT ?;',
            variables: [
              MappedValue.raw(BuiltinDriftType.int, 1),
              MappedValue.raw(BuiltinDriftType.int, 2),
            ],
          )),
          throwsArgumentError);
    });

    test('in runBatched', () {
      expect(
        db.executeBatch(StatementBatch(sql: [
          'SELECT ?; SELECT ?;'
        ], statements: [
          StatementInBatch(
            0,
            StatementInfo.fromText(
              'SELECT ?; SELECT ?;',
              variables: [
                MappedValue.raw(BuiltinDriftType.int, 1),
                MappedValue.raw(BuiltinDriftType.int, 2),
              ],
            ),
          ),
        ])),
        throwsArgumentError,
      );
    });
  });

  test('throwing in setup prevents the database from being opened', () async {
    const exception = 'exception';
    final db = TodoDb(NativeDatabase.memory(setup: (_) => throw exception));

    await expectLater(db.initialize(), throwsA(exception));

    // Should also prevent subsequent open attempts
    await expectLater(db.initialize(), throwsA(exception));
  });

  test('disposes statements directly if cache is disabled', () async {
    final underlying = sqlite3.openInMemory();
    final db = TodoDb(
        NativeDatabase.opened(underlying, cachePreparedStatements: false));
    addTearDown(db.close);

    await db.initialize();
    await db.customStatement('CREATE TABLE foo (bar INTEGER);');
    await db.customStatement('UPDATE foo SET bar = 1');

    expect(underlying.activeStatementCount, isZero);
  });

  test('disposes statements eventually if cache is enabled', () async {
    final underlying = sqlite3.openInMemory();
    addTearDown(underlying.dispose);
    final (db, _) = await NativeDatabase.opened(
      underlying,
      cachePreparedStatements: true,
      closeUnderlyingOnClose: false,
    ).open();

    expect(underlying.activeStatementCount, isZero);

    for (var i = 1; i <= PreparedStatementsCache.defaultSize; i++) {
      await db
          .execute(StatementInfo.fromText('SELECT $i', needsResultSet: true));
      expect(underlying.activeStatementCount, i);
    }

    for (var i = 0; i < PreparedStatementsCache.defaultSize; i++) {
      // This will evict old statements, so the amount of active statements
      // should not change.
      await db.execute(
          StatementInfo.fromText('SELECT $i as "new"', needsResultSet: true));
      expect(
          underlying.activeStatementCount, PreparedStatementsCache.defaultSize);
    }

    await db.close();
    expect(underlying.activeStatementCount, isZero);
  });

  test('does not cache explain statements', () async {
    final db = TodoDb(NativeDatabase.memory(cachePreparedStatements: true));
    addTearDown(db.close);

    await db.customStatement(
        'create table test(id integer primary key, description text)');
    await db.customStatement('create index i1 on test(description)');
    // The schema is locked while an explain is active, so caching this
    // statement makes the test fail at the `drop index` statement.
    await db.customSelect(
      'explain query plan select * from test where description = ?',
      variables: [
        (BuiltinDriftType.text, 't'),
      ],
    ).get();
    await db.customStatement('drop index i1');
    await db.customSelect(
      'explain query plan select * from test where description = ?',
      variables: [
        (BuiltinDriftType.text, 't'),
      ],
    ).get();
  });

  group('can disable migrations', () {
    Future<void> runTest(DriftConnection executor) async {
      final db = TodoDb(executor);
      db.migration = MigrationStrategy(
        onCreate: (_) => fail('should not call onCreate'),
        onUpgrade: (_, __, ___) => fail('should not call onUpgrade'),
        beforeOpen: expectAsync1((details) async {}),
      );
      db.enableMigrations = false;

      addTearDown(db.close);
      final rows = await db.customSelect('select * from sqlite_schema').get();
      expect(rows, isEmpty);
    }

    test(
      'with native database',
      () => runTest(NativeDatabase.blocking(File(d.path('test.db')))),
    );

    test(
      'createInBackground',
      () => runTest(NativeDatabase.createInBackground(
        File(d.path('test.db')),
        enableMigrations: false,
      )),
    );

    test(
      'in background with read pool',
      () => runTest(NativeDatabase.createInBackground(
        File(d.path('test.db')),
        enableMigrations: false,
        readPool: 10,
      )),
    );

    test(
      'opened',
      () => runTest(NativeDatabase.opened(
        sqlite3.openInMemory(),
        closeUnderlyingOnClose: true,
      )),
    );
  });

  test('prevents database access after failed migrations', () async {
    final db = TodoDb(NativeDatabase.memory());
    final exception = 'exception';
    db.migration = MigrationStrategy(onCreate: (_) async => throw exception);

    await expectLater(db.customSelect('SELECT 1').get(), throwsA(exception));

    // The database should now be unusable.
    db.migration = MigrationStrategy();
    await expectLater(db.customSelect('SELECT 1').get(), throwsA(exception));

    await db.close();
  });

  test('customStatement can run multiple statements', () async {
    final db = TodoDb(NativeDatabase.memory());
    db.migration = MigrationStrategy(onCreate: (_) async {
      await db.customStatement('''
CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE groups (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL
);
''');
    });

    await db.customSelect('SELECT * FROM groups').get();
  });
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
