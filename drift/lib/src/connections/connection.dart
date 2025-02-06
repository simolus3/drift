import '../query_builder/compiler.dart';
import 'result_set.dart';

/// An opened database connection used by drift to send generated queries.
abstract interface class OpenedDriftConnection implements DriftSession {}

abstract interface class DriftTransactionParent implements DriftSession {
  Future<DriftTransactionSession> begin(TransactionOptions options);
}

abstract interface class DriftTransactionSession implements DriftSession {
  Future<void> commit();
  Future<void> rollback();
}

abstract interface class DriftSession {
  Future<QueryResult> execute(CompiledStatement statement);
  Future<List<QueryResult>> executeBatch(StatementBatch batch);

  Future<DriftSession> exclusive();

  Future<void> close();
}

final class StatementBatch {
  final String sql;
  final List<CompiledStatement> statements;

  StatementBatch({required this.sql, required this.statements});
}

final class TransactionOptions {}
