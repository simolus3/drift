import 'dart:async';

import 'package:drift/drift.dart';

/// A query executor for drift that delegates work to multiple executors.
abstract class MultiExecutor extends QueryExecutor {
  /// Creates a query executor that will delegate work to different executors.
  ///
  /// Updating statements, or statements that run in a transaction, will be run
  /// with [write]. Select statements outside of a transaction are executed on
  /// [reads].
  factory MultiExecutor({
    required List<QueryExecutor> reads,
    required QueryExecutor write,
  }) =>
      _MultiExecutorImpl(reads: reads, write: write);

  MultiExecutor._();
}

class _ExecutorCompleter {
  _ExecutorCompleter(this.statement, this.args)
      : _completer = Completer<List<Map<String, Object?>>>();

  final String statement;
  final List<Object?> args;
  final Completer<List<Map<String, Object?>>> _completer;

  Future<List<Map<String, Object?>>> get future => _completer.future;

  void complete([FutureOr<List<Map<String, Object?>>>? value]) {
    _completer.complete(value);
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    _completer.completeError(error, stackTrace);
  }
}

class _QueryExecutorPool {
  _QueryExecutorPool(this._executors) : _idleExecutors = [..._executors];

  final List<QueryExecutor> _executors;
  final List<QueryExecutor> _idleExecutors;

  final List<_ExecutorCompleter> _queue = [];
  final List<_ExecutorCompleter> _running = [];

  Future<bool> ensureOpen(QueryExecutorUser user) async {
    final result = await Future.wait(
        _executors.map((QueryExecutor executor) => executor.ensureOpen(user)));
    return result.every((element) => element);
  }

  Future<void> close() async =>
      Future.wait(_executors.map((QueryExecutor executor) => executor.close()));

  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) {
    final executorCompleter = _ExecutorCompleter(statement, args);
    _queue.add(executorCompleter);
    _run();
    return executorCompleter.future;
  }

  void _run() {
    if (_queue.isEmpty) return;
    if (_idleExecutors.isEmpty) return;

    final executor = _idleExecutors.removeAt(0);
    final completer = _queue.removeAt(0);

    _running.add(completer);

    completer.future.whenComplete(() {
      _running.remove(completer);
      _idleExecutors.add(executor);
      _run();
    });

    executor
        .runSelect(completer.statement, completer.args)
        .then(completer.complete, onError: completer.completeError);
  }
}

class _MultiExecutorImpl extends MultiExecutor {
  final _QueryExecutorPool _queryExecutorPool;
  final QueryExecutor _write;

  _MultiExecutorImpl({
    required List<QueryExecutor> reads,
    required QueryExecutor write,
  })  : _queryExecutorPool = _QueryExecutorPool(reads),
        _write = write,
        super._();

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async {
    // note: It's crucial that we open the writes first. The reading connection
    // doesn't run migrations, but has to set the user version.
    return await _write.ensureOpen(user) &&
        await _queryExecutorPool.ensureOpen(_NoMigrationsWrapper(user));
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
          String statement, List<Object?> args) =>
      _queryExecutorPool.runSelect(statement, args);

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
