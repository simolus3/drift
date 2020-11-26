import 'package:moor/backends.dart';

class NullExecutor implements QueryExecutor {
  const NullExecutor();

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError('beginTransaction');
  }

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    throw UnsupportedError('ensureOpen');
  }

  @override
  Future<void> runBatched(BatchedStatements statements) {
    throw UnsupportedError('runBatched');
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) {
    throw UnsupportedError('runCustom');
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) {
    throw UnsupportedError('runDelete');
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    throw UnsupportedError('runInsert');
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) {
    throw UnsupportedError('runSelect');
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    throw UnsupportedError('runUpdate');
  }

  @override
  Future<void> close() => Future.value();

  @override
  SqlDialect get dialect => SqlDialect.sqlite;
}
