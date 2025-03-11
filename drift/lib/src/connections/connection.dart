import '../query_builder/compiler.dart';
import '../query_builder/dialect.dart';
import '../query_builder/types.dart';
import 'result_set.dart';

final class DriftDatabaseImplementation {
  final DriftDialect dialect;
  final Future<DriftRootSession> Function() _openConnection;

  DriftDatabaseImplementation(
      {required this.dialect,
      required Future<DriftRootSession> Function() openConnection})
      : _openConnection = openConnection;

  Future<DriftRootSession> open() {
    return _openConnection();
  }
}

abstract interface class DriftTransactionParent implements DriftSession {
  Future<DriftTransactionSession> begin(TransactionOptions options);
}

abstract interface class DriftSessionWithInternalLocks implements DriftSession {
  Future<DriftSession> exclusive();
}

abstract interface class DriftTransactionSession implements DriftSession {
  Future<void> commit();
  Future<void> rollback();
}

abstract interface class DriftSession {
  Future<QueryResult> execute(StatementInfo statement);
  Future<List<QueryResult>> executeBatch(List<StatementBatch> batch);

  Future<void> close();
}

abstract interface class DriftRootSession implements DriftSession {
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

  StatementInfo(CompiledStatement this.generated)
      : sql = generated.buffer.toString(),
        needsResultSet = generated.resultSetStructure != null,
        variables = generated.variables;

  StatementInfo.fromText(
    this.sql, {
    this.variables = const [],
    this.needsResultSet = false,
  }) : generated = null;

  Iterable<Object?> sqlVariables(DriftDialect dialect) =>
      variables.map((value) {
        return value.$1.sqlParameter(dialect, value);
      });
}

final class TransactionOptions {}
