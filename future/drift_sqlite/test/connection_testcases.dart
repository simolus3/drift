import 'dart:async';

import 'package:async/async.dart';
import 'package:drift3/drift.dart';
import 'package:drift/src/drift3_preview/src/utils/cancellation_zone.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:sqlite3/common.dart';
import 'package:test/test.dart';

void declareConnectionTests(
  Future<OpenedDriftConnection> Function() openConnection,
) {
  Future<OpenedDriftConnection> open() async {
    final impl = await openConnection();
    addTearDown(impl.session.close);
    return impl;
  }

  EmptyDb openDrift() {
    final db = EmptyDb(
      DriftConnection.withImplementation(
        dialect: SqliteDialect.new,
        implementation: openConnection,
      ),
    );
    addTearDown(db.close);
    return db;
  }

  test('schema version', () async {
    final session = (await open()).session;
    final version = session.persistentSchemaVersion!;
    expect(await version.schemaVersion, 0);

    for (var i = 1; i < 10; i++) {
      await version.writeSchemaVersion(i);
      expect(await version.schemaVersion, i);
    }
  });

  test('queries', () async {
    final session = (await open()).session;
    await session.execute(
      StatementInfo('CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY)'),
    );
    await session.execute(StatementInfo('INSERT INTO users DEFAULT VALUES'));

    final rs = await session.execute(
      StatementInfo(
        'SELECT * FROM users',
        isReadOnly: true,
        needsResultSet: true,
      ),
    );
    expect(rs.resultSet!.columnNames, ['id']);
    expect(rs.resultSet!, [
      [1],
    ]);
  });

  test('does not cache explain statements', () async {
    final db = (await open()).session;

    await db.execute(
      StatementInfo(
        'create table test(id integer primary key, description text)',
      ),
    );
    await db.execute(StatementInfo('create index i1 on test(description)'));
    // The schema is locked while an explain is active, so caching this
    // statement makes the test fail at the `drop index` statement.
    await db.execute(
      StatementInfo(
        "explain query plan select * from test where description = ?",
        variables: [
          MappedValue.raw(const SqliteDialect.withOptions().textType, 't'),
        ],
      ),
    );
    await db.execute(StatementInfo('drop index i1'));
    await db.execute(
      StatementInfo(
        "explain query plan select * from test where description = ?",
        variables: [
          MappedValue.raw(const SqliteDialect.withOptions().textType, 't'),
        ],
      ),
    );
  });

  group('nested transactions', () {
    late EmptyDb db;

    setUp(() async {
      db = openDrift();
      await db.customStatement('CREATE TABLE tbl (col);');
    });

    test(
      'outer transaction does not see inner writes after rollback',
      () async {
        await db.transaction(() async {
          await db.customStatement("INSERT INTO tbl (col) VALUES ('outer')");

          try {
            await db.transaction(() async {
              await db.customStatement(
                "INSERT INTO tbl (col) VALUES ('inner')",
              );

              expect(
                await db.customSelect('SELECT * FROM tbl').get(),
                hasLength(2),
              );
              throw Exception('rollback inner');
            });
          } on Exception {
            // Expected rollback, let's continue
          }

          final rows = await db.customSelect('SELECT * FROM tbl').get();
          expect(rows, hasLength(1));
          expect(rows.single.row, ['outer']);
        });
      },
    );

    test('inner writes are visible after completion', () async {
      await db.transaction(() async {
        await db.customStatement("INSERT INTO tbl (col) VALUES ('outer')");

        await db.transaction(() async {
          await db.customStatement("INSERT INTO tbl (col) VALUES ('inner')");
        });

        expect(await db.customSelect('SELECT * FROM tbl').get(), hasLength(2));
      });
    });
  });

  test('concurrent batches cause no problems', () async {
    // https://github.com/simolus3/drift/issues/1882#issuecomment-1312756672
    final db = openDrift();

    final a = db.batch((b) => b.customStatement('CREATE TABLE foo (col)'));
    final b = db.batch((b) => b.customStatement('CREATE TABLE bar (col)'));
    await (a, b).wait;

    await db.customSelect('Select 1').get();
    await db.close();
  });

  test('rolling back after exception with batch in transaction', () async {
    final db = openDrift();
    await db.customStatement('CREATE TABLE tbl (col)');

    const expectedException = 'error';

    expectLater(() async {
      await db.transaction(() async {
        await db.batch((b) {
          b.customStatement("INSERT INTO tbl VALUES ('my content')");
        });

        throw expectedException;
      });
    }, throwsA(expectedException));

    expect(await db.customSelect('SELECT * FROM tbl').get(), isEmpty);
  });

  test('exclusively', () async {
    final db = openDrift();

    bool query1Finished = false;

    // Make a slow query and check that it is not interleaved with other queries/transactions
    final fut1 = db.exclusively<int>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await db.customSelect('SELECT 1').get();
      query1Finished = true;
      return 7;
    });

    final fut2 = db.transaction<int>(() async {
      expect(query1Finished, true);
      return 5;
    });

    final results = await Future.wait<void>([fut1, fut2]);
    expect(results, [7, 5]);
  });

  test('can cancel opening transactions', () async {
    final db = openDrift();
    addTearDown(db.close);

    final hasTransaction = Completer<void>();
    final finishTransaction = Completer<void>();

    db.transaction(() async {
      hasTransaction.complete();
      await finishTransaction.future;
    });
    await hasTransaction.future;

    final token = CancellationToken<void>()..cancel();

    runCancellable(() async {
      await expectLater(
        db.transaction(() async {
          throw 'should not be reached';
        }),
        throwsA(isA<CancellationException>()),
      );
    }, token: token);

    finishTransaction.complete();
    await db.customSelect('SELECT 1').get();
  });

  test('errors throw SqliteExceptions', () async {
    final db = openDrift();
    addTearDown(db.close);

    await expectLater(
      db.customSelect('syntax error for test').get(),
      throwsA(isA<SqliteException>()),
    );
  });

  group('computeWithDatabase', () {
    test('can run computation', () async {
      final db = openDrift();
      await db.customStatement(
        'CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY)',
      );
      addTearDown(db.close);

      final changes = StreamQueue(db.tableUpdates());

      expect(await db.customSelect('SELECT * FROM users').get(), isEmpty);
      await db.computeWithDatabase(
        computation: (db) async {
          await db.batch((b) {
            b.customStatement(
              'INSERT INTO users DEFAULT VALUES;',
              updates: [TableUpdate('users')],
            );
          });
        },
        connect: EmptyDb.new,
      );
      expect(await db.customSelect('SELECT * FROM users').get(), hasLength(1));

      // This should also update the change notification stream.
      await changes.next;
      changes.cancel();
    });

    test('inherits transaction context', () async {
      final db = openDrift();
      await db.customStatement(
        'CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY)',
      );
      addTearDown(db.close);

      await db.transaction(() async {
        await db.customStatement('INSERT INTO users DEFAULT VALUES');

        await db.computeWithDatabase(
          computation: (db) async {
            expect(
              await db.customSelect('SELECT * FROM users').get(),
              hasLength(1),
            );
          },
          connect: EmptyDb.new,
        );
      });
    });
  });
}

final class EmptyDb extends GeneratedDatabase {
  EmptyDb(super.implementation);

  @override
  DatabaseSchema get schema => .empty;

  @override
  final int schemaVersion = 1;
}
