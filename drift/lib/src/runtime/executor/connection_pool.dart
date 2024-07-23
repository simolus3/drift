import 'dart:async';

import 'package:drift/drift.dart';

/// A query executor for drift that delegates work to multiple executors.
sealed class MultiExecutor extends QueryExecutor {
  /// Creates a query executor that will delegate work to different executors.
  ///
  /// Updating statements, or statements that run in a transaction, will be run
  /// with [write]. Select statements outside of a transaction are executed on
  /// [read].
  factory MultiExecutor({
    required QueryExecutor read,
    required QueryExecutor write,
  }) =>
      _MultiExecutorImpl(reads: [read], write: write);

  /// Creates a query executor that will delegate work to different executors.
  ///
  /// Updating statements, or statements that run in a transaction, will be run
  /// with [write]. Select statements outside of a transaction are executed
  /// on distribution in [reads].
  factory MultiExecutor.withReadPool({
    required List<QueryExecutor> reads,
    required QueryExecutor write,
  }) =>
      _MultiExecutorImpl(reads: reads, write: write);
}

class _PendingSelect {
  _PendingSelect(this.statement, this.args)
      : completer = Completer<List<Map<String, Object?>>>();

  final String statement;
  final List<Object?> args;
  final Completer<List<Map<String, Object?>>> completer;
}

class _QueryExecutorPool {
  _QueryExecutorPool(this._executors) : _idleExecutors = [..._executors];

  final List<QueryExecutor> _executors;
  final List<QueryExecutor> _idleExecutors;

  final List<_PendingSelect> _queue = [];
  final List<_PendingSelect> _running = [];

  Future<bool> ensureOpen(QueryExecutorUser user) async {
    final result = await Future.wait(
        _executors.map((QueryExecutor executor) => executor.ensureOpen(user)));
    return result.every((element) => element);
  }

  Future<void> close() async =>
      Future.wait(_executors.map((QueryExecutor executor) => executor.close()));

  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) {
    if (_executors.length == 1) {
      return _executors.single.runSelect(statement, args);
    }

    final executorCompleter = _PendingSelect(statement, args);
    _queue.add(executorCompleter);
    _run();
    return executorCompleter.completer.future;
  }

  void _run() {
    if (_queue.isEmpty) return;
    if (_idleExecutors.isEmpty) return;

    final executor = _idleExecutors.removeAt(0);
    final completer = _queue.removeAt(0);

    _running.add(completer);

    completer.completer.complete(Future.sync(() async {
      try {
        return await executor.runSelect(completer.statement, completer.args);
      } finally {
        _running.remove(completer);
        _idleExecutors.add(executor);
        _run();
      }
    }));
  }
}

class _MultiExecutorImpl implements MultiExecutor {
  final _QueryExecutorPool _queryExecutorPool;
  final QueryExecutor _write;

  @override
  SqlDialect get dialect => _write.dialect;

  _MultiExecutorImpl({
    required List<QueryExecutor> reads,
    required QueryExecutor write,
  })  : _queryExecutorPool = _QueryExecutorPool(reads),
        _write = write;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async {
    // note: It's crucial that we open the writes first. The reading connection
    // doesn't run migrations, but has to set the user version.
    return await _write.ensureOpen(user) &&
        await _queryExecutorPool.ensureOpen(_NoMigrationsWrapper(user));
  }

  @override
  QueryExecutor beginExclusive() {
    // This is technically not correct - readers can still read while the
    // exclusive write is active, but the same thing is true for transactions
    // and since we're using separate connections for reads and writes this
    // should be fine.
    return _write.beginExclusive();
  }

  @override
  TransactionExecutor beginTransaction() => _write.beginTransaction();

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _write.runBatched(statements);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _write.runCustom(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _write.runDelete(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _write.runInsert(statement, args);

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) {
    // TODO: This is horrible, fix with https://github.com/simolus3/drift/issues/3107
    if (statement.contains('RETURNING')) {
      return _write.runSelect(statement, args);
    } else {
      return _queryExecutorPool.runSelect(statement, args);
    }
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _write.runUpdate(statement, args);

  @override
  Future<void> close() async {
    await _write.close();
    await _queryExecutorPool.close();
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
