@TestOn('dart-vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:drift3/drift.dart';
import 'package:drift_sqlite/native.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'connection_testcases.dart';

void main() {
  declareConnectionTests(_openPool);

  test('returns new columns after recompilation', () async {
    // https://github.com/simolus3/drift/issues/2454
    final file = File(d.path('test.db'));
    final session = (await (sqliteConnectionPool(
      file: file,
      amountOfReaders: 1,
    ).open())).session;
    addTearDown(session.close);

    await session.execute(StatementInfo('create table t (c1)'));
    await session.execute(StatementInfo('insert into t values (1)'));

    final before = await session.execute(
      StatementInfo('select * from t', needsResultSet: true),
    );
    expect(before.resultSet, [
      [1],
    ]);

    await session.execute(StatementInfo('alter table t add column c2'));

    final after = await session.execute(
      StatementInfo('select * from t', needsResultSet: true),
    );
    expect(after.resultSet, [
      [1, null],
    ]);
  });

  test('can use a custom setup function', () async {
    final file = File(d.path('test.db'));
    final session = (await sqliteConnectionPool(
      file: file,
      amountOfReaders: 1,
      configureDatabase: (db, {required bool isWriter}) {
        db.execute('CREATE TEMPORARY TABLE conn_info(info text);');
        db.execute('INSERT INTO conn_info(info) VALUES (?)', [
          isWriter ? 'writer' : 'reader',
        ]);
      },
    ).open()).session;
    addTearDown(session.close);

    final writeResult = await session.execute(
      StatementInfo('SELECT * FROM conn_info', needsResultSet: true),
    );
    expect(writeResult.resultSet, [
      ['writer'],
    ]);

    final readResult = await session.execute(
      StatementInfo(
        'SELECT * FROM conn_info',
        needsResultSet: true,
        isReadOnly: true,
      ),
    );
    expect(readResult.resultSet, [
      ['reader'],
    ]);
  });

  test('throwing in setup prevents the database from being opened', () async {
    const exception = 'exception';
    expect(
      sqliteConnectionPool(
        file: File(d.path('test.db')),
        configureDatabase: (db, {required bool isWriter}) => throw exception,
      ).open(),
      throwsA(exception),
    );
  });

  test('can cancel queries', () async {
    final db = EmptyDb(
      sqliteConnectionPool(file: File(d.path('test.db')), amountOfReaders: 1),
    );

    // Occupy the single read connection
    final hasTransaction = Completer<void>();
    final completeTransaction = Completer<void>();
    db.transaction(() async {
      hasTransaction.complete();
    }, options: TransactionOptions(readOnly: true));
    await hasTransaction.future;

    // A query that reports an error if run. We don't handle the error so it
    // would fail the test, but the query never runs since the connection is
    // blocked until we cancel the query.
    final subscription = db
        .customSelect("SELECT json('invalid')")
        .watch()
        .listen(null);
    await pumpEventQueue();
    await subscription.cancel();

    completeTransaction.complete();
    await db.close();
  });

  for (final mode in UpdateNotificationMode.values) {
    group('with update mode ${mode.name}', () {
      test('can watch changes from other isolate', () async {
        final path = d.path('test.db');
        final db = EmptyDb(
          sqliteConnectionPool(
            file: File(path),
            amountOfReaders: 1,
            updates: mode,
          ),
        );
        await db.customStatement('CREATE TABLE foo (bar TEXT);');
        final updates = StreamQueue(db.tableUpdates(.onTableName('foo')));

        await Isolate.run(() async {
          final db = EmptyDb(
            sqliteConnectionPool(
              file: File(path),
              amountOfReaders: 1,
              updates: mode,
            ),
          );

          switch (mode) {
            case .native:
              await db.customInsert('INSERT INTO foo DEFAULT VALUES');
            case .drift:
              // Ensure the database is opened.
              await db.currentSession();
              db.notifyUpdates({TableUpdate('foo')});
          }

          await db.close();
        });

        expect(updates, emits({TableUpdate('foo')}));
      });
    });
  }
}

Future<OpenedDriftConnection> _openPool() async {
  final file = File(d.path('test.db'));
  return sqliteConnectionPool(file: file).open();
}
