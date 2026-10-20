@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../generated/todos.dart';

void main() {
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

    test('read pool cannot be negative', () {
      final file = File(d.path('test.db'));

      expect(
        () => NativeDatabase.createInBackground(file, readPool: -4),
        throwsRangeError,
      );
    });

    test('read pool', () async {
      final file = File(d.path('test.db'));

      final db = TodoDb(
        NativeDatabase.createInBackground(
          file,
          setup: (db) {
            var counter = 0;

            db.createFunction(
              functionName: 'inc_counter',
              function: (args) => counter++,
            );
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
              final counter = row.data['r'] as int;
              expect(
                counter < 20,
                isTrue,
                reason:
                    'should distribute somewhat evenly, counter is $counter',
              );
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
      final db = NativeDatabase.opened(underlying);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(() => underlying.execute('SELECT 1'), throwsStateError);
    });

    test('can avoid disposing the underlying instance', () async {
      final underlying = sqlite3.openInMemory();
      final db = NativeDatabase.opened(
        underlying,
        closeUnderlyingOnClose: false,
      );
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(() => underlying.execute('SELECT 1'), isNot(throwsA(anything)));
      underlying.close();
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
        db.runBatched(
          BatchedStatements(
            ['SELECT ?; SELECT ?;'],
            [ArgumentsForBatchedStatement(0, [])],
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  test('calls setup twice if first invocation fails', () async {
    const exception = 'exception';
    var count = 0;
    final db = NativeDatabase.memory(
      setup: expectAsync1((_) {
        if (count++ == 0) {
          throw exception;
        }
      }, count: 2),
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
    final db = NativeDatabase.opened(
      underlying,
      cachePreparedStatements: false,
    );
    addTearDown(db.close);

    await db.ensureOpen(_FakeExecutorUser());
    await db.runCustom('CREATE TABLE foo (bar INTEGER);');
    await db.runCustom('UPDATE foo SET bar = 1');
  });

  test('does not cache explain statements', () async {
    final db = NativeDatabase.memory(cachePreparedStatements: true);
    addTearDown(db.close);
    await db.ensureOpen(_FakeExecutorUser());

    await db.runCustom(
      'create table test(id integer primary key, description text)',
    );
    await db.runCustom('create index i1 on test(description)');
    // The schema is locked while an explain is active, so caching this
    // statement makes the test fail at the `drop index` statement.
    await db.runSelect(
      'explain query plan select * from test where description = ?',
      ['t'],
    );
    await db.runCustom('drop index i1');
    await db.runSelect(
      'explain query plan select * from test where description = ?',
      ['t'],
    );
  });

  test('runSelect with duplicate column names', () async {
    final db = NativeDatabase.memory();
    addTearDown(db.close);
    await db.ensureOpen(_FakeExecutorUser());

    final rows = await db.runSelect('SELECT 1 AS a, 2 AS b, 3 AS a', []);
    expect(rows, [
      {'a': 3, 'b': 2},
    ]);
    expect(rows.single.keys, ['a', 'b']);
    expect(rows.single['c'], null);

    final row = rows.single;
    expect(() => row['a'] = 0, throwsUnsupportedError);
    expect(() => row.remove('a'), throwsUnsupportedError);
    expect(() => row.clear(), throwsUnsupportedError);
    expect(() => row.addAll({'c': 1}), throwsUnsupportedError);
    expect(row, {'a': 3, 'b': 2});
  });

  group('can disable migrations', () {
    Future<void> runTest(QueryExecutor executor) async {
      final db = TodoDb(executor);
      db.migration = MigrationStrategy(
        onCreate: (_) => fail('should not call onCreate'),
        onUpgrade: (_, _, _) => fail('should not call onUpgrade'),
        beforeOpen: expectAsync1((details) async {}),
      );

      addTearDown(db.close);
      final rows = await db.customSelect('select * from sqlite_schema').get();
      expect(rows, isEmpty);
    }

    test(
      'with native database',
      () => runTest(
        NativeDatabase(File(d.path('test.db')), enableMigrations: false),
      ),
    );

    test(
      'createInBackground',
      () => runTest(
        NativeDatabase.createInBackground(
          File(d.path('test.db')),
          enableMigrations: false,
        ),
      ),
    );

    test(
      'createBackgroundConnection',
      () => runTest(
        NativeDatabase.createBackgroundConnection(
          File(d.path('test.db')),
          enableMigrations: false,
        ),
      ),
    );

    test(
      'in background with read pool',
      () => runTest(
        NativeDatabase.createBackgroundConnection(
          File(d.path('test.db')),
          enableMigrations: false,
          readPool: 10,
        ),
      ),
    );

    test(
      'opened',
      () => runTest(
        NativeDatabase.opened(
          sqlite3.openInMemory(),
          enableMigrations: false,
          closeUnderlyingOnClose: true,
        ),
      ),
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
    db.migration = MigrationStrategy(
      onCreate: (_) async {
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
      },
    );

    await db.customSelect('SELECT * FROM groups').get();
  });

  group('custom sqlite bindings', () {
    test('synchronous file', () async {
      final mockSqlite = _MockSqlite();

      final db = NativeDatabase(File('/dev/null'), sqlite3: () => mockSqlite);

      await expectLater(
        TodoDb(db).customSelect('SELECT 1').get(),
        throwsA(anything),
      );

      expect(mockSqlite.openedPaths, contains('/dev/null'));
    });

    test('createInBackground', () async {
      final db = NativeDatabase.createInBackground(
        File('/dev/null'),
        sqlite3: _MockSqlite.new,
      );

      await expectLater(
        TodoDb(db).customSelect('SELECT 1').get(),
        throwsA(
          isA<Object>().having(
            (e) => e.toString(),
            'toString',
            contains('mock sqlite open'),
          ),
        ),
      );
    });

    test('memory', () async {
      final mockSqlite = _MockSqlite();

      final db = NativeDatabase.memory(sqlite3: () => mockSqlite);

      await expectLater(
        TodoDb(db).customSelect('SELECT 1').get(),
        throwsA(
          isA<Object>().having(
            (e) => e.toString(),
            'toString',
            contains('mock sqlite openInMemory'),
          ),
        ),
      );
    });
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

final class _MockSqlite implements Sqlite3 {
  final openedPaths = <String>[];
  bool didOpenInMemory = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'stub';
  }

  @override
  Database open(
    String filename, {
    String? vfs,
    OpenMode mode = OpenMode.readWriteCreate,
    bool uri = false,
    bool? mutex,
  }) {
    openedPaths.add(filename);
    throw UnimplementedError('mock sqlite open');
  }

  @override
  Database openInMemory({String? vfs}) {
    didOpenInMemory = true;
    throw UnimplementedError('mock sqlite openInMemory');
  }
}
