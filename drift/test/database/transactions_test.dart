@TestOn('!browser')
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;
  late MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streamQueries);
    db = TodoDb.connect(connection);
  });

  test('streams in transactions are isolated and scoped', () async {
    // create a database without mocked stream queries
    db = TodoDb(MockExecutor());

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
          .map((r) => r.readInt('_mocked_'))
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

  test('nested transactions use the outer transaction', () async {
    await db.transaction(() async {
      await db.transaction(() async {
        // todo how can we test that these are really equal?
      });

      // the outer callback has not completed yet, so shouldn't send
      verifyNever(executor.transactions.send());
    });

    verify(executor.transactions.send());
  });

  test('code in callback uses transaction', () async {
    // notice how we call .select on the database, but it should be called on
    // transaction executor.
    await db.transaction(() async {
      await db.select(db.users).get();
    });

    verifyNever(executor.runSelect(any, any));
    verify(executor.transactions.runSelect(any, any));
  });

  test('transactions rollback after errors', () async {
    final exception = Exception('oh no');
    final future = db.transaction(() async {
      throw exception;
    });

    await expectLater(future, throwsA(exception));

    verifyNever(executor.transactions.send());
    verify(executor.transactions.rollback());
  });

  test('transactions notify about table updates after completing', () async {
    final transactions = executor.transactions;
    when(transactions.runUpdate(any, any)).thenAnswer((_) => Future.value(2));

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
    verify(executor.transactions.send());
  });

  test('the database is opened before starting a transaction', () async {
    await db.transaction(() async {
      verify(executor.ensureOpen(db));
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
      db.transaction(() => Future.error(cause)),
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
    when(transactions.send()).thenAnswer((_) => Future.error(commitException));
    when(transactions.rollback())
        .thenAnswer((_) => Future.error(rollbackException));

    return expectLater(
      db.transaction(Future.value),
      throwsA(isA<CouldNotRollBackException>()
          .having((e) => e.cause, 'cause', commitException)
          .having((e) => e.exception, 'exception', rollbackException)),
    );
  });
}
