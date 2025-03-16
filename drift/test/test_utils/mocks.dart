import 'package:drift/drift.dart';
import 'package:drift/src/connections/sqlite3/connection.dart';
import 'package:sqlite3/common.dart' as sqlite3;
import 'package:mockito/mockito.dart';

final class MockSession extends Mock
    implements
        DriftRootSession,
        DriftTransactionParent,
        DriftSessionWithInternalLocks {
  late final MockTransactionSession transactions = MockTransactionSession();
  late final MockSession exclusiveExecutor = this;

  var open = true;

  MockSession() {
    when(execute(any)).thenAnswer((i) async {
      assert(open);
      final statement = i.positionalArguments[0] as StatementInfo;
      if (statement.needsResultSet) {
        return QueryResult(
          resultSet: SqliteResultSet(
            resultSet: sqlite3.ResultSet(const [], const [], const []),
          ),
        );
      } else {
        return QueryResult(resultSet: null);
      }
    });
    when(executeBatch(any)).thenAnswer((i) async {
      assert(open);
      return const [];
    });
    when(close()).thenAnswer((_) async {
      assert(open);
      open = false;
    });

    when(schemaVersion).thenAnswer((i) async {
      assert(open);
      return 0;
    });
    when(writeSchemaVersion(any)).thenAnswer((i) async {
      assert(open);
    });
    when(exclusive()).thenAnswer((i) async {
      assert(open);
      return exclusiveExecutor;
    });
    when(begin(any)).thenAnswer((i) async {
      assert(open);
      return transactions;
    });
  }

  @override
  Future<QueryResult> execute(StatementInfo? statement) => _nsm(
      Invocation.method(#execute, [statement]),
      Future.value(QueryResult(resultSet: null)));

  @override
  Future<List<QueryResult>> executeBatch(List<StatementBatch>? statement) =>
      _nsm(Invocation.method(#executeBatch, [statement]),
          Future.value(const []));

  @override
  Future<void> close() =>
      _nsm(Invocation.method(#close, []), Future<void>.value());

  @override
  Future<int> get schemaVersion =>
      _nsm(Invocation.getter(#schemaVersion), Future.value(0));

  @override
  Future<void> writeSchemaVersion(int? version) => _nsm(
      Invocation.method(#writeSchemaVersion, [version]), Future<void>.value());

  @override
  Future<DriftSession> exclusive() =>
      _nsm(Invocation.method(#exclusive, []), Future.value(exclusiveExecutor));

  @override
  Future<DriftTransactionSession> begin(TransactionOptions? options) =>
      _nsm(Invocation.method(#begin, [options]), Future.value(transactions));
}

final class MockTransactionSession extends MockSession
    implements DriftTransactionSession {
  MockTransactionSession() {
    when(commit()).thenAnswer((_) => Future.value(null));
    when(rollback()).thenAnswer((_) => Future.value(null));
  }

  @override
  Future<void> commit() {
    return _nsm(Invocation.method(#commit, []), Future.value(null));
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
