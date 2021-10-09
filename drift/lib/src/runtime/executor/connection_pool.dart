import 'package:drift/backends.dart';
import 'package:drift/drift.dart';

/// A query executor for drift that delegates work to multiple executors.
abstract class MultiExecutor extends QueryExecutor {
  /// Creates a query executor that will delegate work to different executors.
  ///
  /// Updating statements, or statements that run in a transaction, will be run
  /// with [write]. Select statements outside of a transaction are executed on
  /// [read].
  factory MultiExecutor(
      {required QueryExecutor read, required QueryExecutor write}) {
    return _MultiExecutorImpl(read, write);
  }

  MultiExecutor._();
}

class _MultiExecutorImpl extends MultiExecutor {
  final QueryExecutor _reads;
  final QueryExecutor _writes;

  _MultiExecutorImpl(this._reads, this._writes) : super._();

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async {
    // note: It's crucial that we open the writes first. The reading connection
    // doesn't run migrations, but has to set the user version.
    await _writes.ensureOpen(user);
    await _reads.ensureOpen(_NoMigrationsWrapper(user));

    return true;
  }

  @override
  TransactionExecutor beginTransaction() {
    return _writes.beginTransaction();
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    await _writes.runBatched(statements);
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {
    await _writes.runCustom(statement, args);
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) async {
    return await _writes.runDelete(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    return await _writes.runInsert(statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) async {
    return await _reads.runSelect(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    return await _writes.runUpdate(statement, args);
  }

  @override
  Future<void> close() async {
    await _writes.close();
    await _reads.close();
  }
}

class _NoMigrationsWrapper extends QueryExecutorUser {
  final QueryExecutorUser inner;

  _NoMigrationsWrapper(this.inner);

  @override
  int get schemaVersion => inner.schemaVersion;

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {
    // don't run any migrations
  }
}
