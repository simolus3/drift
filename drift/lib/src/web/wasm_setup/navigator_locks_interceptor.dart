import 'dart:async';

import 'package:drift/drift.dart';
import 'package:web/web.dart' show LockManager, AbortController;

import '../../runtime/cancellation_zone.dart';
import 'shared.dart';

/// Request navigator locks around database queries to prevent contention across
/// two tabs using the same database file concurrently.

final class NavigatorLocksExecutor implements QueryExecutor {
  final QueryExecutor _inner;
  final String _name;
  final LockManager _locks = locks!;

  /// @nodoc
  NavigatorLocksExecutor(this._inner, String name) : _name = 'drift-db-$name';

  @override
  QueryExecutor beginExclusive() {
    final inner = _inner.beginExclusive();
    return inner.interceptWith(
      _AcquireNavigatorLockInterceptor(this, ownsLock: inner),
    );
  }

  @override
  TransactionExecutor beginTransaction() {
    final inner = _inner.beginTransaction();
    return inner.interceptWith(
          _AcquireNavigatorLockInterceptor(this, ownsLock: inner),
        )
        as TransactionExecutor;
  }

  @override
  SqlDialect get dialect => _inner.dialect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    return _withLock(() => _inner.ensureOpen(user));
  }

  @override
  Future<void> runBatched(BatchedStatements statements) {
    return _withLock(() => _inner.runBatched(statements));
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) {
    return _withLock(() => _inner.runCustom(statement, args));
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) {
    return _withLock(() => _inner.runDelete(statement, args));
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    return _withLock(() => _inner.runInsert(statement, args));
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) {
    return _withLock(() => _inner.runSelect(statement, args));
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    return _withLock(() => _inner.runUpdate(statement, args));
  }

  @override
  Future<void> close() {
    return _inner.close();
  }

  Future<void> _acquireLock(Completer<void> returnLock) async {
    checkIfCancelled();
    final abort = AbortController();
    doOnCancellation(() => abort.abort());

    return await _locks.acquire(_name, returnLock);
  }

  Future<T> _withLock<T>(Future<T> Function() block) async {
    final completeLock = Completer<void>();
    try {
      await _acquireLock(completeLock);
      return await block();
    } finally {
      completeLock.complete();
    }
  }
}

/// A query interceptor that acquires a navigator lock before opening the inner
/// executor and returns it after the inner executor is closed.
final class _AcquireNavigatorLockInterceptor extends QueryInterceptor {
  final NavigatorLocksExecutor _executor;
  final Completer<void> _returnNavigatorLocks = Completer();

  /// The executor whose commit, rollback or close ends this interceptor's
  /// navigator-lock scope. Executors for nested transactions flow through
  /// this same interceptor but must not complete the shared completer.
  /// See https://github.com/simolus3/drift/issues/3870
  final QueryExecutor _ownsNavigatorLock;

  Future<void>? _acquiredNavigatorLock;

  _AcquireNavigatorLockInterceptor(
    this._executor, {
    required QueryExecutor ownsLock,
  }) : _ownsNavigatorLock = ownsLock;

  @override
  Future<bool> ensureOpen(
    QueryExecutor executor,
    QueryExecutorUser user,
  ) async {
    final acquired = _acquiredNavigatorLock ??= _executor._acquireLock(
      _returnNavigatorLocks,
    );
    await acquired;

    return executor.ensureOpen(user);
  }

  @override
  Future<void> close(QueryExecutor inner) {
    return inner.close().whenComplete(() => _releaseLock(inner));
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) {
    return inner.send().whenComplete(() => _releaseLock(inner));
  }

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) {
    return inner.rollback().whenComplete(() => _releaseLock(inner));
  }

  void _releaseLock(QueryExecutor inner) {
    // A nested transaction completes before the outermost one; releasing the
    // navigator lock here would make the outer commit fail with
    // `Bad state: Future already completed` and its rollback hang forever.
    if (identical(inner, _ownsNavigatorLock)) {
      _returnNavigatorLocks.complete();
    }
  }
}
