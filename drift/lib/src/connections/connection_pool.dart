import 'dart:async';

import '../../dialect/sqlite.dart';
import 'connection.dart';
import 'connection_compat.dart';
import 'result_set.dart';

abstract class _ConnectionPool
    implements
        DriftSession,
        DriftTransactionParent,
        DriftRootSession,
        DriftSessionWithInternalLocks {
  /// Acquire a [DriftRootSession] from the pool.
  ///
  /// Returns the session and a function that returns it to the pool.
  Future<(DriftSession, void Function())> _acquireSession(
      {required bool forWrite});

  Future<T> _withSession<T>(Future<T> Function(DriftSession) inner,
      {required bool forWrite}) async {
    final (session, returnSession) = await _acquireSession(forWrite: forWrite);
    try {
      return await inner(session);
    } finally {
      returnSession();
    }
  }

  @override
  DriftTransactionParent? get transactionParent => this;

  @override
  DriftSessionWithInternalLocks? get locks => this;

  @override
  DriftRootSession? get root => this;

  @override
  DriftTransactionSession? get transaction => null;

  @override
  Future<DriftSession> begin(TransactionOptions options) async {
    final (session, returnSession) = await _acquireSession(forWrite: true);
    var needsToReturnSession = true;

    try {
      // DriftSessionPool wraps the writing session in a compat session if
      // necessary, they will always support starting transactions.
      final parent = session.transactionParent!;
      final transaction = await parent.begin(options);

      transaction.closed.whenComplete(returnSession);
      needsToReturnSession = false;
      return transaction;
    } finally {
      if (needsToReturnSession) {
        returnSession();
      }
    }
  }

  @override
  Future<DriftSession> exclusive() async {
    final (session, returnSession) = await _acquireSession(forWrite: true);
    var needsToReturnSession = true;

    try {
      // DriftSessionPool wraps the writing session in a compat session if
      // necessary, they will always support exclusive locks.
      final inner =
          await (session as DriftSessionWithInternalLocks).exclusive();
      inner.closed.whenComplete(returnSession);
      return inner;
    } finally {
      if (needsToReturnSession) {
        returnSession();
      }
    }
  }

  @override
  Future<QueryResult> execute(StatementInfo statement) {
    return _withSession(
      forWrite: !statement.isReadOnly,
      (session) => session.execute(statement),
    );
  }

  @override
  Future<List<QueryResult>> executeBatch(List<StatementBatch> batch) {
    return _withSession(
      forWrite: true,
      (session) => session.executeBatch(batch),
    );
  }
}

final class _PendingSessionInvocation {
  final Completer<DriftSession> obtainSession = Completer();
  final Completer<void> returnSession = Completer();
}

/// A pool handing out leases to connections with [acquire].
final class _ReadSessionPool {
  final List<DriftSession> _executors;
  final List<DriftSession> _idleExecutors;

  final List<_PendingSessionInvocation> _queue = [];
  final List<_PendingSessionInvocation> _running = [];

  _ReadSessionPool(this._executors) : _idleExecutors = [..._executors];

  Future<(DriftSession, void Function())> acquire() async {
    final pending = _PendingSessionInvocation();
    _enqueue(pending);

    final session = await pending.obtainSession.future;
    return (session, pending.returnSession.complete);
  }

  void _enqueue(_PendingSessionInvocation invocation) {
    if (_idleExecutors.isNotEmpty) {
      _runWith(invocation, _idleExecutors.removeAt(0));
    } else {
      _queue.add(invocation);
      _processQueue();
    }
  }

  void _runWith(_PendingSessionInvocation invocation, DriftSession session) {
    _running.add(invocation);
    invocation.obtainSession.complete(session);
    invocation.returnSession.future.whenComplete(() {
      if (!session.isClosed) {
        _idleExecutors.add(session);

        if (_queue.isNotEmpty) {
          _processQueue();
        }
      }
    });
  }

  void _processQueue() {
    if (_queue.isEmpty) return;
    if (_idleExecutors.isEmpty) return;

    final executor = _idleExecutors.removeAt(0);
    final completer = _queue.removeAt(0);

    _runWith(completer, executor);
  }

  Future<void> close() async {
    await Future.wait([
      for (var i = 0; i < _executors.length; i++) _closeOne(),
    ]);

    assert(_idleExecutors.isEmpty);
  }

  Future<void> _closeOne() async {
    final (session, release) = await acquire();
    try {
      await session.close();
    } finally {
      release();
    }
  }
}

/// A [DriftSession] implementation that delegates queries to multiple other
/// sessions.
final class DriftSessionPool extends _ConnectionPool {
  final _ReadSessionPool _reads;
  final DriftSession _writes;
  final DriftSession _compatWrites;

  final Completer<void> _closed = Completer();

  DriftSessionPool._(this._reads, this._writes, this._compatWrites);

  /// Creates a query executor that will delegate work to different executors.
  ///
  /// Updating statements, or statements that run in a transaction, will be run
  /// with [write]. Select statements outside of a transaction are executed
  /// on [reads].
  factory DriftSessionPool({
    required DriftSession write,
    required List<DriftSession> reads,
  }) {
    DriftSession compatWrites = write;

    if (write is! DriftTransactionParent ||
        write is! DriftSessionWithInternalLocks) {
      compatWrites = DriftCompatibilitySession(
          inner: write, dialect: const SqliteDialect());
    }

    return DriftSessionPool._(_ReadSessionPool(reads), write, compatWrites);
  }

  @override
  Future<(DriftSession, void Function())> _acquireSession(
      {required bool forWrite}) async {
    if (forWrite) {
      return (_compatWrites, () {});
    } else {
      return await _reads.acquire();
    }
  }

  @override
  Future<void> close() {
    if (!isClosed) {
      _closed.complete(Future(() async {
        await _reads.close();
        await _compatWrites.close();
      }));
    }

    return closed;
  }

  @override
  Future<int> get schemaVersion => _writes.root!.schemaVersion;

  @override
  Future<void> writeSchemaVersion(int version) =>
      _writes.root!.writeSchemaVersion(version);

  @override
  Future<void> get closed => _closed.future;

  @override
  bool get isClosed => _closed.isCompleted;
}
