import 'dart:async';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../test_utils/test_utils.dart';

class _FakeExecutorUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 1;
}

void main() {
  late MockDatabaseDelegate delegate;
  setUp(() {
    delegate = MockDatabaseDelegate();
    provideDummy<TransactionDelegate>(const NoTransactionDelegate());
    provideDummy<DbVersionDelegate>(const NoVersionDelegate());

    when(delegate.isOpen).thenAnswer((_) => Future.value(true));
    when(delegate.runSelect(any, any))
        .thenAnswer((_) => Future.value(QueryResult.fromRows([])));
    when(delegate.runUpdate(any, any)).thenAnswer((_) => Future.value(3));
    when(delegate.runInsert(any, any)).thenAnswer((_) => Future.value(4));
    when(delegate.runCustom(any, any)).thenAnswer((_) => Future.value());
    when(delegate.runBatched(any)).thenAnswer((_) => Future.value());
  });

  group('delegates queries', () {
    void runTests(bool sequential) {
      test('when sequential = $sequential', () async {
        final db = DelegatedDatabase(delegate, isSequential: sequential);
        await db.ensureOpen(_FakeExecutorUser());

        expect(await db.runSelect('select', const []), isEmpty);
        expect(await db.runUpdate('update', const []), 3);
        expect(await db.runInsert('insert', const []), 4);
        await db.runCustom('custom');
        final batched = BatchedStatements([], []);
        await db.runBatched(batched);

        verifyInOrder([
          delegate.isOpen,
          delegate.runSelect('select', const []),
          delegate.runUpdate('update', const []),
          delegate.runInsert('insert', const []),
          delegate.runCustom('custom', const []),
          delegate.runBatched(batched),
        ]);
      });
    }

    runTests(false);
    runTests(true);
  });

  group('migrations', () {
    late DelegatedDatabase db;
    final userDb = CustomQueryExecutorUser(
      schemaVersion: 3,
      beforeOpenCallback: (self, executor, details) async {
        await executor.ensureOpen(self);

        if (details.wasCreated) {
          await executor.runCustom('created', []);
        } else if (details.hadUpgrade) {
          await executor.runCustom(
              'updated', [details.versionBefore, details.versionNow]);
        }
      },
    );

    setUp(() {
      when(delegate.isOpen).thenAnswer((_) => Future.value(false));
      db = DelegatedDatabase(delegate);
    });

    test('when the database does not support versions', () async {
      when(delegate.versionDelegate).thenReturn(const NoVersionDelegate());
      await db.ensureOpen(userDb);

      verify(delegate.open(userDb));
      verifyNever(delegate.runCustom(any, any));
    });

    test('when the database supports versions at opening', () async {
      when(delegate.versionDelegate)
          .thenReturn(OnOpenVersionDelegate(() => Future.value(3)));
      await db.ensureOpen(userDb);

      verify(delegate.open(userDb));
      verifyNever(delegate.runCustom(any, any));
    });

    test('when the database supports dynamic version', () async {
      final version = MockDynamicVersionDelegate();
      when(version.schemaVersion).thenAnswer((_) => Future.value(3));
      when(delegate.versionDelegate).thenReturn(version);
      await db.ensureOpen(userDb);

      verify(delegate.open(userDb));
      verifyNever(delegate.runCustom(any, any));
      verify(version.schemaVersion);
      // Not running migrations from version 3 to 3
      verifyNever(version.setSchemaVersion(3));

      when(version.schemaVersion).thenAnswer((_) => Future.value(2));
      await db.ensureOpen(userDb);
      // Running migrations from version 2 to 3
      verify(version.setSchemaVersion(3));
    });

    test('handles database creations', () async {
      when(delegate.versionDelegate)
          .thenReturn(OnOpenVersionDelegate(() => Future.value(0)));
      await db.ensureOpen(userDb);

      verify(delegate.runCustom('created', []));
    });

    test('handles database upgrades', () async {
      when(delegate.versionDelegate)
          .thenReturn(OnOpenVersionDelegate(() => Future.value(1)));
      await db.ensureOpen(userDb);

      verify(delegate.runCustom('updated', argThat(equals([1, 3]))));
    });

    test('handles database downgrades', () async {
      final version = MockDynamicVersionDelegate();
      when(version.schemaVersion).thenAnswer((_) => Future.value(4));
      when(delegate.versionDelegate).thenReturn(version);
      await db.ensureOpen(userDb);

      verify(delegate.open(userDb));
      verify(delegate.runCustom('updated', argThat(equals([4, 3]))));
      verify(version.setSchemaVersion(3));
    });
  });

  group('transactions', () {
    late DelegatedDatabase db;

    setUp(() {
      db = DelegatedDatabase(delegate, isSequential: true);
    });

    test('when the delegate does not support transactions', () async {
      when(delegate.transactionDelegate)
          .thenReturn(const NoTransactionDelegate());
      await db.ensureOpen(_FakeExecutorUser());

      final transaction = db.beginTransaction();
      await transaction.ensureOpen(_FakeExecutorUser());
      await transaction.runSelect('SELECT 1;', const []);
      await transaction.send();

      verifyInOrder([
        delegate.runCustom('BEGIN TRANSACTION', []),
        delegate.runSelect('SELECT 1;', const []),
        delegate.runCustom('COMMIT TRANSACTION', []),
      ]);
    });

    test('when committing or rolling back fails', () async {
      when(delegate.transactionDelegate)
          .thenReturn(const NoTransactionDelegate());
      await db.ensureOpen(_FakeExecutorUser());
      when(delegate.runCustom('COMMIT TRANSACTION', []))
          .thenAnswer((i) => Future.error('cannot commit'));
      when(delegate.runCustom('ROLLBACK TRANSACTION', []))
          .thenAnswer((i) => Future.error('cannot rollback'));

      final transaction = db.beginTransaction();
      await transaction.ensureOpen(_FakeExecutorUser());
      await transaction.runSelect('SELECT 1;', const []);
      await expectLater(() async {
        try {
          await transaction.send();
        } catch (e) {
          await transaction.rollback();
        }
      }, throwsA('cannot rollback'));

      // Ensure that the database is still usable after this mishap
      await db.runSelect('SELECT 1', const []);
    });

    test('when the database supports transactions', () async {
      final transactionDelegate = MockSupportedTransactionDelegate();
      when(transactionDelegate.startTransaction(any)).thenAnswer((i) {
        (i.positionalArguments.single as void Function(
            QueryDelegate))(delegate);
      });
      when(transactionDelegate.managesLockInternally).thenReturn(true);

      when(delegate.transactionDelegate).thenReturn(transactionDelegate);

      await db.ensureOpen(_FakeExecutorUser());
      final transaction = db.beginTransaction();
      await transaction.ensureOpen(_FakeExecutorUser());
      await transaction.send();

      verify(transactionDelegate.startTransaction(any));
    });

    test('supported transactions - begin fails', () async {
      final transactionDelegate = MockSupportedTransactionDelegate();
      final exception = Exception('expected');

      when(transactionDelegate.startTransaction(any)).thenAnswer((i) async {
        throw exception;
      });
      when(transactionDelegate.managesLockInternally).thenReturn(true);

      when(delegate.transactionDelegate).thenReturn(transactionDelegate);

      await db.ensureOpen(_FakeExecutorUser());
      final transaction = db.beginTransaction();

      await expectLater(
          transaction.ensureOpen(_FakeExecutorUser()), throwsA(exception));
      // This is a no-op now that shouldn't throw
      await transaction.send();

      verify(transactionDelegate.startTransaction(any));
    });

    test('supported transactions - commit fails', () async {
      final transactionDelegate = MockSupportedTransactionDelegate();
      final exception = Exception('expected');

      when(transactionDelegate.startTransaction(any)).thenAnswer((i) async {
        await (i.positionalArguments.single as Future<Object?> Function(
            QueryDelegate))(delegate);
        throw exception;
      });
      when(transactionDelegate.managesLockInternally).thenReturn(true);

      when(delegate.transactionDelegate).thenReturn(transactionDelegate);

      await db.ensureOpen(_FakeExecutorUser());
      final transaction = db.beginTransaction();
      await transaction.ensureOpen(_FakeExecutorUser());
      await expectLater(transaction.send(), throwsA(exception));

      verify(transactionDelegate.startTransaction(any));
    });
  });

  group('beginExclusive', () {
    late DelegatedDatabase db;

    setUp(() {
      db = DelegatedDatabase(delegate, isSequential: true);
    });

    test('locks the database when opened', () async {
      await db.ensureOpen(_FakeExecutorUser());

      final exclusiveA = db.beginExclusive();
      final exclusiveB = db.beginExclusive();

      await exclusiveA.ensureOpen(_FakeExecutorUser());
      final second = Completer<bool>.sync();
      exclusiveB.ensureOpen(_FakeExecutorUser()).then(second.complete);

      await pumpEventQueue();
      expect(second.isCompleted, isFalse);

      await exclusiveA.close();
      await second.future;
      await exclusiveB.close();
    });

    test('prevents concurrent transactions', () async {
      await db.ensureOpen(_FakeExecutorUser());

      final exclusive = db.beginExclusive();
      final transaction = db.beginTransaction();

      await exclusive.ensureOpen(_FakeExecutorUser());
      final second = Completer<bool>.sync();
      transaction.ensureOpen(_FakeExecutorUser()).then(second.complete);

      await pumpEventQueue();
      expect(second.isCompleted, isFalse);

      await exclusive.close();
      await second.future;
      await transaction.close();
    });

    test('supports transactions', () async {
      await db.ensureOpen(_FakeExecutorUser());

      final exclusive = db.beginExclusive();
      await exclusive.ensureOpen(_FakeExecutorUser());

      final transaction = exclusive.beginTransaction();
      await transaction.ensureOpen(_FakeExecutorUser());

      final outerDone = Completer<void>.sync();
      exclusive.runCustom('').then(outerDone.complete);

      await pumpEventQueue();
      expect(outerDone.isCompleted, isFalse);

      await transaction.send();
      await outerDone.future;
      await exclusive.close();
    });
  });

  group('open and close', () {
    test('throws when being used before ensureOpen is complete', () async {
      final db = DelegatedDatabase(delegate);
      expect(db.runSelect('', []), throwsA(isA<StateError>()));
    });

    test('does not do anything when closing before opening', () async {
      final db = DelegatedDatabase(delegate);
      await db.close();

      verifyNever(delegate.close());
    });

    test('throws when opening after closing', () async {
      final db = DelegatedDatabase(delegate);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(db.ensureOpen(_FakeExecutorUser()), throwsStateError);
    });

    test('throws when using after closing', () async {
      final db = DelegatedDatabase(delegate);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(db.runSelect('SELECT 1', []), throwsStateError);
    });

    test('does not close more than once', () async {
      final db = DelegatedDatabase(delegate);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();
      await db.close();

      verify(delegate.close()).called(1);
    });
  });
}
