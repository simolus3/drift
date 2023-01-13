import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';

class MockExecutor extends Mock implements QueryExecutor {
  late final MockTransactionExecutor transactions = MockTransactionExecutor();
  final OpeningDetails? openingDetails;
  bool _opened = false;

  MockExecutor([this.openingDetails]) {
    when(dialect).thenReturn(SqlDialect.sqlite);
    when(runSelect(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value([]);
    });
    when(runUpdate(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value(0);
    });
    when(runDelete(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value(0);
    });
    when(runInsert(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value(0);
    });
    when(runCustom(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value();
    });
    when(runBatched(any)).thenAnswer((_) {
      assert(_opened);
      return Future.value();
    });

    when(ensureOpen(any)).thenAnswer((i) async {
      if (!_opened && openingDetails != null) {
        _opened = true;
        await (i.positionalArguments.single as QueryExecutorUser)
            .beforeOpen(this, openingDetails!);
      }

      _opened = true;

      return true;
    });

    when(close()).thenAnswer((_) async {
      _opened = false;
    });
  }

  @override
  SqlDialect get dialect =>
      _nsm(Invocation.getter(#dialect), SqlDialect.sqlite);

  @override
  Future<bool> ensureOpen(QueryExecutorUser? user) =>
      _nsm(Invocation.method(#ensureOpen, [user]), Future.value(true));

  @override
  Future<List<Map<String, Object?>>> runSelect(
          String? statement, List<Object?>? args) =>
      _nsm(Invocation.method(#runSelect, [statement, args]),
          Future.value(<Map<String, Object?>>[]));

  @override
  Future<int> runInsert(String? statement, List<Object?>? args) =>
      _nsm(Invocation.method(#runInsert, [statement, args]), Future.value(0));

  @override
  Future<int> runUpdate(String? statement, List<Object?>? args) =>
      _nsm(Invocation.method(#runUpdate, [statement, args]), Future.value(0));

  @override
  Future<int> runDelete(String? statement, List<Object?>? args) =>
      _nsm(Invocation.method(#runDelete, [statement, args]), Future.value(0));

  @override
  Future<void> runCustom(String? statement, [List<Object?>? args]) => _nsm(
      Invocation.method(#runCustom, [statement, args]), Future.value(null));

  @override
  Future<void> runBatched(BatchedStatements? statements) =>
      _nsm(Invocation.method(#runBatched, [statements]), Future.value(null));

  @override
  TransactionExecutor beginTransaction() =>
      _nsm(Invocation.method(#beginTransaction, []), transactions) ??
      transactions;

  @override
  Future<void> close() =>
      _nsm(Invocation.method(#close, []), Future.value(null));
}

class MockTransactionExecutor extends MockExecutor
    implements TransactionExecutor {
  MockTransactionExecutor() {
    when(supportsNestedTransactions).thenReturn(true);
    when(send()).thenAnswer((_) => Future.value(null));
    when(rollback()).thenAnswer((_) => Future.value(null));
  }

  @override
  bool get supportsNestedTransactions {
    return _nsm(Invocation.getter(#supportsNestedTransactions), true);
  }

  @override
  Future<void> send() {
    return _nsm(Invocation.method(#send, []), Future.value(null));
  }

  @override
  Future<void> rollback() =>
      _nsm(Invocation.method(#rollback, []), Future.value(null));
}

extension on Mock {
  T _nsm<T>(Invocation invocation, Object? returnValue) {
    return noSuchMethod(invocation, returnValue: returnValue) as T;
  }
}
