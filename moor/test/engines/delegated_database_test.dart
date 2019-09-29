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

        await db.doWhenOpened((_) async {
          expect(await db.runSelect(null, null), isEmpty);
          expect(await db.runUpdate(null, null), 3);
          expect(await db.runInsert(null, null), 4);
          await db.runCustom(null);
          await db.runBatched(null);
        });

        verifyInOrder([
          delegate.isOpen,
          delegate.runSelect(null, null),
          delegate.runUpdate(null, null),
          delegate.runInsert(null, null),
          delegate.runCustom(null, []),
          delegate.runBatched(null),
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
      db = DelegatedDatabase(delegate)..databaseInfo = userDb;

      when(userDb.handleDatabaseCreation(executor: anyNamed('executor')))
          .thenAnswer((i) async {
        final executor = i.namedArguments.values.single as SqlExecutor;
        await executor('created', []);
      });

      when(userDb.handleDatabaseVersionChange(
        executor: anyNamed('executor'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((i) async {
        final executor = i.namedArguments[#executor] as SqlExecutor;
        final from = i.namedArguments[#from] as int;
        final to = i.namedArguments[#to] as int;
        await executor('upgraded', [from, to]);
      });
    });

    test('when the database does not support versions', () async {
      when(delegate.versionDelegate).thenReturn(const NoVersionDelegate());
      await db.doWhenOpened((_) async {});

      verify(delegate.open(userDb));
      verifyNever(delegate.runCustom(any, any));
    });

    test('when the database supports versions at opening', () async {
      when(delegate.versionDelegate)
          .thenReturn(OnOpenVersionDelegate(() => Future.value(3)));
      await db.doWhenOpened((_) async {});

      verify(delegate.open(userDb));
      verifyNever(delegate.runCustom(any, any));
    });

    test('when the database supports dynamic version', () async {
      final version = _MockDynamicVersionDelegate();
      when(version.schemaVersion).thenAnswer((_) => Future.value(3));

      when(delegate.versionDelegate).thenReturn(version);
      await db.doWhenOpened((_) async {});

      verify(delegate.open(userDb));
      verifyNever(delegate.runCustom(any, any));
      verify(version.schemaVersion);
      verify(version.setSchemaVersion(3));
    });

    test('handles database creations', () async {
      when(delegate.versionDelegate)
          .thenReturn(OnOpenVersionDelegate(() => Future.value(0)));
      await db.doWhenOpened((_) async {});

      verify(delegate.runCustom('created', []));
    });

    test('handles database upgrades', () async {
      when(delegate.versionDelegate)
          .thenReturn(OnOpenVersionDelegate(() => Future.value(1)));
      await db.doWhenOpened((_) async {});

      verify(delegate.runCustom('upgraded', [1, 3]));
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
      await db.doWhenOpened((_) async {
        final transaction = db.beginTransaction();
        await transaction.doWhenOpened((e) async {
          await e.runSelect(null, null);

          await transaction.send();
        });
      });

      verifyInOrder([
        delegate.runCustom('BEGIN TRANSACTION', []),
        delegate.runSelect(null, null),
        delegate.runCustom('COMMIT TRANSACTION', []),
      ]);
    });

    test('when the database supports transactions', () async {
      final transaction = _MockTransactionDelegate();
      when(transaction.startTransaction(any)).thenAnswer((i) {
        (i.positionalArguments.single as Function(QueryDelegate))(delegate);
      });

      when(delegate.transactionDelegate).thenReturn(transaction);

      await db.doWhenOpened((_) async {
        final transaction = db.beginTransaction();
        await transaction.doWhenOpened((e) async {
          await e.runSelect(null, null);

          await transaction.send();
        });
      });

      verify(transaction.startTransaction(any));
    });
  });
}
