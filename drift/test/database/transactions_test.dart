@TestOn('!browser')
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockSession executor;
  late MockStreamQueries streamQueries;

  setUp(() {
    executor = MockSession();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streams: streamQueries);
    db = TodoDb(connection);
  });

  test('streams in transactions are isolated and scoped', () async {
    // create a database without mocked stream queries
    db = TodoDb(createConnection(executor));

    late Stream<int?> stream;

    final didSetUpStream = Completer<void>();
    final makeUpdate = Completer<void>();
    final complete = Completer<void>();

    final transaction = db.transaction(() async {
      stream = db
          .customSelect(
            'SELECT _mocked_',
            readsFrom: {db.users},
          )
          .map((r) => r.read<int>('_mocked_'))
          .watchSingleOrNull();
      didSetUpStream.complete();

      await makeUpdate.future;
      db.markTablesUpdated({db.users});

      await complete.future;
    });

    final emittedValues = <dynamic>[];
    var didComplete = false;

    // wait for the transaction to setup the stream
    await didSetUpStream.future;
    stream.listen(emittedValues.add, onDone: () => didComplete = true);

    // Stream should emit initial select
    await pumpEventQueue();
    expect(emittedValues, hasLength(1));

    // update tables inside the transaction -> stream should emit another value
    makeUpdate.complete();
    await pumpEventQueue();
    expect(emittedValues, hasLength(2));

    // update tables outside of the transaction -> stream should NOT update
    db.markTablesUpdated({db.users});
    await pumpEventQueue();
    expect(emittedValues, hasLength(2));

    complete.complete();
    await transaction;
    expect(didComplete, isTrue, reason: 'Stream must complete');
  });

  test('stream queries terminate on exceptional transaction', () async {
    late Stream stream;

    try {
      await db.transaction(() async {
        stream = db.select(db.users).watch();
        throw Exception();
      });
    } on Exception {
      // ignore
    }

    expect(stream, emitsDone);
  });

  group('nested transactions', () {
    test('are emulated if not supported', () async {
      final transactions = executor.transactions;
      when(transactions.transactionParent).thenReturn(null);

      await db.transaction(() async {
        await db.transaction(() async {
          await db.customSelect('SELECT 1').get();
        });

        // the outer callback has not completed yet, so shouldn't send
        verifyNever(executor.transactions.commit());
      });

      verify(transactions.executeSql('SAVEPOINT s1;'));
      verify(transactions.executeSql('SELECT 1'));
      verify(transactions.executeSql('RELEASE s1;'));
      verify(transactions.commit());
      verify(executor.begin(any));
      verifyNever(transactions.begin(any));
    });

    test('are committed separately', () async {
      final outerTransactions = executor.transactions;
      final innerTransactions = outerTransactions.transactions;

      await db.transaction(() async {
        verify(executor.begin(any));

        await db.transaction(() async {
          await db.select(db.todosTable).get();
        });

        verify(outerTransactions.begin(any));
        verify(innerTransactions.executeSql(contains('SELECT')));
        verify(innerTransactions.commit());
      });

      verify(outerTransactions.commit());
    });

    test('are rolled back after exceptions', () async {
      final outerTransactions = executor.transactions;
      final innerTransactions = outerTransactions.transactions;

      await db.transaction(() async {
        verify(executor.begin(any));
        final cause = Exception('revert inner');

        await expectLater(db.transaction(() async {
          // Some bogus query so that the transaction is actually opened.
          await db.select(db.todosTable).get();
          throw cause;
        }), throwsA(cause));

        verify(outerTransactions.begin(any));
        verify(innerTransactions.execute(any));
        verify(innerTransactions.rollback());
      });

      verify(outerTransactions.commit());
    });
  });

  test('code in callback uses transaction', () async {
    // notice how we call .select on the database, but it should be called on
    // transaction executor.
    await db.initialize();
    clearInteractions(executor);

    await db.transaction(() async {
      await db.select(db.users).get();
    });

    verifyNever(executor.execute(any));
    verify(executor.transactions.execute(any));
  });

  test('transactions rollback after errors', () async {
    final exception = Exception('oh no');
    final future = db.transaction(() async {
      throw exception;
    });

    await expectLater(future, throwsA(exception));

    verifyNever(executor.transactions.commit());
    verify(executor.transactions.rollback());
  });

  test('transactions notify about table updates after completing', () async {
    final transactions = executor.transactions;
    when(transactions.execute(any))
        .thenAnswer((_) async => queryResult(null, affectedRows: 2));

    await db.transaction(() async {
      await db
          .update(db.users)
          .write(const UsersCompanion(name: Value('Updated name')));

      // Even though we just wrote to users, this only happened inside the
      // transaction, so the top level stream queries should not be updated.
      verifyZeroInteractions(streamQueries);
    });

    // After the transaction completes, the queries should be updated
    verify(
      streamQueries.handleTableUpdates(
          {TableUpdate.onTable(db.users, kind: UpdateKind.update)}),
    ).called(1);
    verify(executor.transactions.commit());
  });

  test('the database is opened before starting a transaction', () async {
    await db.transaction(() async {
      verify(executor.schemaVersion);
    });
  });

  test('transaction return value', () async {
    final actual = await db.transaction(() async => 1);
    expect(actual, 1);
  });

  test('reports original exception when rollback throws', () {
    const rollbackException = 'rollback';
    const cause = 'original cause';

    final transactions = executor.transactions;
    when(transactions.rollback())
        .thenAnswer((_) => Future.error(rollbackException));

    return expectLater(
      db.transaction(() => Future<void>.error(cause)),
      throwsA(isA<CouldNotRollBackException>()
          .having((e) => e.cause, 'cause', cause)
          .having((e) => e.exception, 'exception', rollbackException)),
    );
  });

  test('reports original exception when rollback throws after failed commit',
      () {
    const rollbackException = 'rollback';
    const commitException = 'commit';

    final transactions = executor.transactions;
    when(transactions.commit())
        .thenAnswer((_) => Future.error(commitException));
    when(transactions.rollback())
        .thenAnswer((_) => Future.error(rollbackException));

    return expectLater(
      db.transaction(Future.value),
      throwsA(isA<CouldNotRollBackException>()
          .having((e) => e.cause, 'cause', commitException)
          .having((e) => e.exception, 'exception', rollbackException)),
    );
  });

  group('statements run in correct zone', () {
    // Statements used to run in the executor of the zone that created them, but
    // they should actually run in the zone that calls the async method starting
    // the database operation (https://github.com/simolus3/drift/issues/2873).

    test('select', () async {
      when(executor.execute(any)).thenAnswer((i) {
        final arg = i.positionalArguments[0] as StatementInfo;
        if (arg.needsResultSet) {
          return Future.error('should run select in transaction');
        } else {
          return Future.value(queryResult([]));
        }
      });

      final simpleQuery = db.select(db.users);
      final joinedQuery = db.selectOnly(db.users)..addColumns([db.users.id]);
      final customQuery = db.customSelect('SELECT 1');

      await db.transaction(() async {
        expect(await simpleQuery.get(), isEmpty);
        expect(await joinedQuery.get(), isEmpty);
        expect(await customQuery.get(), isEmpty);
      });
    });

    test('update', () async {
      when(executor.execute(any)).thenAnswer((i) {
        final arg = i.positionalArguments[0] as StatementInfo;
        if (arg.expectedWrites.isNotEmpty) {
          return Future.error('should run update in transaction');
        } else {
          return Future.value(queryResult([]));
        }
      });

      final stmt = db.update(db.users);
      await db.transaction(() async {
        await stmt.write(UsersCompanion(isAwesome: Value(true)));
      });

      verify(executor.transactions
          .executeSql('UPDATE "users" SET "is_awesome" = ?1;', [1]));
    });

    test('delete', () async {
      when(executor.execute(any)).thenAnswer((i) {
        final arg = i.positionalArguments[0] as StatementInfo;
        if (arg.expectedWrites.isNotEmpty) {
          return Future.error('should run delete in transaction');
        } else {
          return Future.value(queryResult([]));
        }
      });

      final stmt = db.delete(db.users);
      await db.transaction(() async {
        await stmt.go();
      });

      verify(executor.transactions.executeSql('DELETE FROM "users";', []));
    });

    test('insert', () async {
      when(executor.execute(any)).thenAnswer((i) {
        final arg = i.positionalArguments[0] as StatementInfo;
        if (arg.expectedWrites.isNotEmpty) {
          return Future.error('should run update in transaction');
        } else {
          return Future.value(queryResult([]));
        }
      });

      final transactions = executor.transactions;
      when(transactions.execute(any)).thenAnswer((i) {
        return Future.value(queryResult([], lastInsertRowId: 1));
      });

      final stmt = db.into(db.categories);

      await db.transaction(() async {
        await stmt.insert(CategoriesCompanion.insert(description: 'test'));
        await stmt.insertReturningOrNull(
            CategoriesCompanion.insert(description: 'test2'));
      });

      verify(executor.transactions.executeSql(
          'INSERT INTO "categories" ("desc") VALUES (?1)', ['test']));
      verify(executor.transactions.executeSql(
          'INSERT INTO "categories" ("desc") VALUES (?1) RETURNING *',
          ['test2']));
    });
  });
}
