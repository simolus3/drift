import 'dart:async';
import 'dart:js_interop';

import 'package:drift/drift.dart';
import 'package:web/web.dart'
    show AbortController, DOMException, LockManager, LockOptions;

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
    return _inner.beginExclusive().interceptWith(
      _AcquireNavigatorLockInterceptor(this),
    );
  }

  @override
  TransactionExecutor beginTransaction() {
    return _inner.beginTransaction().interceptWith(
          _AcquireNavigatorLockInterceptor(this),
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

  Future<void> _acquireLock(Completer<void> returnLock) {
    return _locks.acquire(_name, returnLock);
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

  Future<void>? _acquiredNavigatorLock;

  _AcquireNavigatorLockInterceptor(this._executor);

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
    return inner.close().whenComplete(() => _returnNavigatorLocks.complete());
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) {
    return inner.send().whenComplete(() => _returnNavigatorLocks.complete());
  }

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) {
    return inner.rollback().whenComplete(
      () => _returnNavigatorLocks.complete(),
    );
  }
}

extension on LockManager {
  Future<void> acquire(String lockName, Completer<void> returnLock) {
    checkIfCancelled();
    final abort = AbortController();
    doOnCancellation(() => abort.abort());

    final hasLock = Completer<void>.sync();

    JSPromise callback() {
      hasLock.complete();
      return returnLock.future.toJS;
    }

    request(
      lockName,
      LockOptions(signal: abort.signal),
      Zone.current.bindCallback(callback).toJS,
    ).toDart.onError((e, s) {
      final domError = e as DOMException;

      if (domError.name == 'AbortError') {
        hasLock.completeError(const CancellationException());
      } else {
        hasLock.completeError(e);
      }

      return null;
    });

    return hasLock.future;
  }
}
