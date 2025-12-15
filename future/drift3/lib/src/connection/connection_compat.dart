import 'dart:async';

import 'package:meta/meta.dart';

import 'connection.dart';
import 'result_set.dart';
import '../query_builder/dialect.dart';
import '../query_builder/statements/transactions.dart';
import '../utils/synchronized.dart';
import '../utils/cancellation_zone.dart';

/// A [DriftSession] implementation that supports all features drift expects
/// of underlying database implementations, even if the inner session doesn't.
///
/// Mainly, this implements transactions with manual `BEGIN` and `COMMIT`
/// statements.
@internal
final class DriftCompatibilitySession
    implements
        DriftSession,
        DriftTransactionParent,
        DriftSessionWithInternalLocks {
  final DriftSession _inner;
  final DriftDialect _dialect;

  final Completer<void> _closed = Completer.sync();

  /// Whether this session has explicitly been closed.
  bool _isClosed = false;

  /// We use a shared lock when executing statements (since we provide no
  /// ordering guarantees for concurrent statements).
  /// For transactions or [exclusive] blocks not implemented by the [_inner]
  /// session, we use an exclusive lock to ensure that these blocks don't
  /// interleave with statements not supposed to run outside of them.
  final SharedOrExclusiveLock _lock = SharedOrExclusiveLock();

  final int _transactionDepth;

  DriftCompatibilitySession._(
    this._inner,
    this._dialect,
    this._transactionDepth,
  ) {
    _inner.closed.whenComplete(() {
      if (!_closed.isCompleted) {
        _isClosed = true;
        _closed.complete();
      }
    });
  }

  /// Wraps [inner] as a compatibility session, using [dialect] to generate
  /// transaction-related commands if not supported by the inner session.
  DriftCompatibilitySession({
    required DriftSession inner,
    required DriftDialect dialect,
  }) : this._(inner, dialect, -1);

  void _checkOpen() {
    if (_isClosed) {
      throw StateError('''
This database or transaction runner has already been closed and may not be used
anymore.

If this is happening in a transaction, you might be using the transaction
without awaiting every statement in it.''');
    }
  }

  Future<T> _startNested<T extends DriftCompatibilitySession>(
    FutureOr<T> Function() create,
  ) {
    final opened = Completer<T>();

    _synchronized(shared: false, () async {
      _checkOpen();

      final inner = await create();
      opened.complete(inner);

      // Keep locked until the inner session completes
      await inner._closed.future;
    });

    return opened.future;
  }

  Future<T> _synchronized<T>(
    Future<T> Function() action, {
    bool abortIfCancelled = true,
    bool shared = true,
  }) {
    final lock = shared ? _lock.shared : _lock.exclusive;

    return lock(() async {
      if (abortIfCancelled) checkIfCancelled();
      return await action();
    });
  }

  @override
  Object? get tag => _inner.tag;

  @override
  PersistentSchemaVersion? get persistentSchemaVersion =>
      _inner.persistentSchemaVersion;

  @override
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => this;

  @override
  DriftSessionWithInternalLocks? get locks => this;

  @override
  Future<DriftCompatibilityTransaction> begin(
    TransactionOptions options,
  ) async {
    _checkOpen();

    if (_inner.transactionParent case final supported?) {
      return DriftCompatibilityTransaction._(
        true,
        await supported.begin(options),
        _dialect,
        _transactionDepth + 1,
      );
    } else {
      return _startNested(() async {
        await _inner.execute(
          _dialect.compile(BeginStatement(depth: _transactionDepth + 1)),
        );

        if (options.deferForeignKeys == true) {
          await _inner.execute(
            StatementInfo('pragma defer_foreign_keys = on;'),
          );
        }

        return DriftCompatibilityTransaction._(
          false,
          _inner,
          _dialect,
          _transactionDepth + 1,
        );
      });
    }
  }

  Future<void> _closeInner() => _inner.close();

  @override
  Future<void> get closed => _closed.future;

  @override
  bool get isClosed => _isClosed;

  @override
  Future<void> close() async {
    await _synchronized(abortIfCancelled: false, () async {
      if (!_isClosed) {
        _isClosed = true;
        await _closeInner();
      }
    });

    // Closing the inner session will close this one as well.
    await closed;
  }

  @override
  Future<DriftCompatibilitySession> exclusive() async {
    _checkOpen();

    if (_inner case DriftSessionWithInternalLocks locks) {
      return DriftCompatibilitySession._(
        await locks.exclusive(),
        _dialect,
        _transactionDepth,
      );
    } else {
      return await _startNested(
        () =>
            (_DriftCompatibilityExclusive(_inner, _dialect, _transactionDepth)),
      );
    }
  }

  @override
  Future<QueryResult> execute(StatementInfo statement) async {
    return await _synchronized(() async {
      _checkOpen();
      return _inner.execute(statement);
    });
  }

  @override
  Future<List<QueryResult>> executeBatch(StatementBatch batch) async {
    return await _synchronized(() async {
      _checkOpen();
      return _inner.executeBatch(batch);
    });
  }
}

/// A [DriftCompatibilitySession] that is also acting as a
/// [DriftTransactionSession].
final class DriftCompatibilityTransaction extends DriftCompatibilitySession
    implements DriftTransactionSession {
  /// Whether this is using [inner] to drive the transaction.
  ///
  /// When false, there's an outer session that is locked while this transaction
  /// is active and we implement transactions with a pair of `BEGIN` / `COMMIT`
  /// or `SAVEPOINT` / `RELEASE` commands.
  final bool _isUsingUnderlyingTransaction;

  DriftCompatibilityTransaction._(
    this._isUsingUnderlyingTransaction,
    super._inner,
    super._dialect,
    super._transactionDepth,
  ) : super._();

  @override
  DriftTransactionSession? get transaction => this;

  @override
  Future<void> close() async {
    assert(!isClosed);

    if (_isUsingUnderlyingTransaction) {
      await _inner.close();
    } else {
      await rollback();
    }
  }

  @override
  Future<void> commit() async {
    assert(!isClosed);

    if (_isUsingUnderlyingTransaction) {
      await (_inner as DriftTransactionSession).commit();
    } else {
      await _inner.execute(
        _dialect.compile(CommitStatement(depth: _transactionDepth)),
      );
      _closed.complete();
    }
  }

  @override
  Future<void> rollback() async {
    assert(!isClosed);

    if (_isUsingUnderlyingTransaction) {
      await (_inner as DriftTransactionSession).rollback();
    } else {
      await _inner.execute(
        _dialect.compile(RollbackStatement(depth: _transactionDepth)),
      );
      _closed.complete();
    }
  }
}

final class _DriftCompatibilityExclusive extends DriftCompatibilitySession {
  _DriftCompatibilityExclusive(
    super._inner,
    super._dialect,
    super._transactionDepth,
  ) : super._();

  @override
  Future<void> _closeInner() async {
    // We just need to release the lock, the underlying session stays open.
  }
}
