import 'compiler.dart';
import 'results.dart';

/// A database connection used by drift to send generated queries.
abstract interface class DriftConnection implements DriftSession {}

abstract interface class DriftTransactionSession implements DriftSession {
  Future<void> commit();
  Future<void> rollback();
}

abstract interface class DriftSession {
  Future<RawResultSet> execute(CompiledStatement statement);
}
