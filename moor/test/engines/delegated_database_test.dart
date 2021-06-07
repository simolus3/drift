//@dart=2.9
import 'package:mockito/mockito.dart';
import 'package:moor/backends.dart';
import 'package:moor/moor.dart';
import 'package:test/test.dart';

class _MockDelegate extends Mock implements DatabaseDelegate {}

class _MockUserDb extends Mock implements GeneratedDatabase {}

class _MockDynamicVersionDelegate extends Mock
    implements DynamicVersionDelegate {}

class _MockTransactionDelegate extends Mock
    implements SupportedTransactionDelegate {}

class _FakeExecutorUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 1;
}

void main() {
  _MockDelegate delegate;
  setUp(() {
    delegate = _MockDelegate();

    when(delegate.isOpen).thenAnswer((_) => Future.value(true));
    when(delegate.runSelect(any, any))
        .thenAnswer((_) => Future.value(QueryResult.fromRows([])));
    when(delegate.runUpdate(any, any)).thenAnswer((_) => Future.value(3));
    when(delegate.runInsert(any, any)).thenAnswer((_) => Future.value(4));
    when(delegate.runCustom(any, any)).thenAnswer((_) => Future.value());
    when(delegate.runBatched(any)).thenAnswer((_) => Future.value());
  });

  group('delegates queries', () {
    void _runTests(bool sequential) {
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

    _runTests(false);
    _runTests(true);
  });

  group('migrations', () {
    DelegatedDatabase db;
    _MockUserDb userDb;
    setUp(() {
      userDb = _MockUserDb();
      when(userDb.schemaVersion).thenReturn(3);

      when(delegate.isOpen).thenAnswer((_) => Future.value(false));
      db = DelegatedDatabase(delegate);

      when(userDb.beforeOpen(any, any)).thenAnswer((i) async {
        final executor = i.positionalArguments[0] as QueryExecutor;
        final details = i.positionalArguments[1] as OpeningDetails;

        await executor.ensureOpen(userDb);

        if (details.wasCreated) {
          await executor.runCustom('created', []);
        } else if (details.hadUpgrade) {
          await executor.runCustom(
              'updated', [details.versionBefore, details.versionNow]);
        }
      });
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
      final version = _MockDynamicVersionDelegate();
      when(version.schemaVersion).thenAnswer((_) => Future.value(3));

      when(delegate.versionDelegate).thenReturn(version);
      await db.ensureOpen(userDb);

      verify(delegate.open(userDb));
      verifyNever(delegate.runCustom(any, any));
      verify(version.schemaVersion);
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
  });

  group('transactions', () {
    DelegatedDatabase db;

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

    test('when the database supports transactions', () async {
      final transactionDelegate = _MockTransactionDelegate();
      when(transactionDelegate.startTransaction(any)).thenAnswer((i) {
        (i.positionalArguments.single as Function(QueryDelegate))(delegate);
      });

      when(delegate.transactionDelegate).thenReturn(transactionDelegate);

      await db.ensureOpen(_FakeExecutorUser());
      final transaction = db.beginTransaction();
      await transaction.ensureOpen(_FakeExecutorUser());
      await transaction.send();

      verify(transactionDelegate.startTransaction(any));
    });
  });

  group('open and close', () {
    test('throws when being used before ensureOpen is complete', () async {
      final db = DelegatedDatabase(delegate);
      expect(db.runSelect('', []), throwsA(isA<AssertionError>()));
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

    test('does not close more than once', () async {
      final db = DelegatedDatabase(delegate);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();
      await db.close();

      verify(delegate.close()).called(1);
    });
  });
}
