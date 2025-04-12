import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/src/connections/result_set.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

QueryResult queryResult(
  List<Map<String, Object?>>? rows, {
  int? affectedRows,
  int? lastInsertRowId,
}) {
  return QueryResult(
    resultSet: switch (rows) {
      null => null,
      _ => RawResultSet.generate(
          rows.length, (i, rs) => RawRow.byMap(resultSet: rs, values: rows[i]))
    },
    affectedRows: affectedRows,
    lastInsertRowId: lastInsertRowId,
  );
}

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
          resultSet: RawResultSet.generate(0, (_, __) => throw 'unreachable'),
          affectedRows: 0,
          lastInsertRowId: 0,
        );
      } else {
        return QueryResult(
            resultSet: null, affectedRows: 0, lastInsertRowId: 0);
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
          Future.value(const <QueryResult>[]));

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
      _nsm(Invocation.method(#exclusive, []), _neverComplete<DriftSession>());

  @override
  Future<DriftTransactionSession> begin(TransactionOptions? options) => _nsm(
      Invocation.method(#begin, [options]),
      _neverComplete<DriftTransactionSession>());

  /// Utility for asserting that a given SQL statement was executed.
  Future<QueryResult> executeSql(Object? sql, [Object? variables = isEmpty]) =>
      execute(
        argThat(
          isA<StatementInfo>().having((e) => e.sql, 'sql', sql).having(
              (e) => e.variables.map((e) => e.$2), 'variables', variables),
        ),
      );

  static Future<T> _neverComplete<T>() => Completer<T>().future;
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
