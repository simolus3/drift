import '../query_builder/compiler.dart';
import '../query_builder/dialect.dart';
import '../query_builder/types.dart';
import '../runtime/streams/store.dart';
import '../runtime/streams/store_impl.dart';
import '../runtime/streams/update_rules.dart';
import 'result_set.dart';

final class DriftDatabaseImplementation {
  final DriftDialect dialect;
  final Future<DriftSession> Function() _openConnection;

  final StreamQueryStore? streamQueries;

  DriftDatabaseImplementation({
    required this.dialect,
    required Future<DriftSession> Function() openConnection,
    this.streamQueries,
  }) : _openConnection = openConnection;

  Future<(DriftSession, StreamQueryStore)> open() async {
    final session = await _openConnection();
    return (session, streamQueries ?? LocalStreamQueryStore());
  }
}

abstract interface class DriftTransactionParent {
  Future<DriftSession> begin(TransactionOptions options);
}

abstract interface class DriftSessionWithInternalLocks {
  Future<DriftSession> exclusive();
}

abstract interface class DriftTransactionSession {
  Future<void> commit();
  Future<void> rollback();
}

abstract interface class DriftSession {
  Future<QueryResult> execute(StatementInfo statement);
  Future<List<QueryResult>> executeBatch(List<StatementBatch> batch);

  /// If this session has schema management method, a [DriftRootSession]
  /// instance exposing them.
  DriftRootSession? get root;

  /// If this session represents a a transaction, returns a
  /// [DriftTransactionSession] that can be used to commit or rollback the
  /// transaction.
  ///
  /// This getter should always return the same value, existing session
  /// instances can't start being a transaction after being open.
  DriftTransactionSession? get transaction;

  /// If this session can open transactions, a [DriftTransactionParent] through
  /// which transactions can be started.
  DriftTransactionParent? get transactionParent;

  /// If this session can be locked, a [DriftSessionWithInternalLocks] instance
  /// through which an exclusive lock on the session can be obtained.
  DriftSessionWithInternalLocks? get locks;

  bool get isClosed;
  Future<void> get closed;
  Future<void> close();
}

abstract interface class DriftRootSession {
  Future<int> get schemaVersion;
  Future<void> writeSchemaVersion(int version);
}

final class StatementBatch {
  final String sql;
  final List<StatementInfo> statements;

  StatementBatch({required this.sql, required this.statements});
}

final class StatementInfo {
  final CompiledStatement? generated;

  final String sql;
  final bool needsResultSet;
  final List<TypedNullableValue> variables;
  final Set<TableUpdate> expectedWrites;
  final bool isReadOnly;

  StatementInfo(CompiledStatement this.generated)
      : sql = generated.buffer.toString(),
        needsResultSet = generated.resultSetStructure != null,
        variables = generated.variables,
        expectedWrites = generated.possibleUpdates,
        isReadOnly = generated.isReadOnly;

  StatementInfo.fromText(
    this.sql, {
    this.variables = const [],
    this.needsResultSet = false,
    this.expectedWrites = const {},
    this.isReadOnly = false,
  }) : generated = null;

  Iterable<Object?> sqlVariables(DriftDialect dialect) =>
      variables.map((value) {
        return value.$1.sqlParameterOrNull(dialect, value.$2);
      });

  @override
  String toString() {
    return '$sql, $variables';
  }
}

final class TransactionOptions {
  // We might eventually use this to implement read-only transactions, which can
  // be used to optimize connection pools.
}
