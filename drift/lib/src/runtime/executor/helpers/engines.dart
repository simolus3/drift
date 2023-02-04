import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../utils/synchronized.dart';
import '../../cancellation_zone.dart';
import 'delegates.dart';

abstract class _BaseExecutor extends QueryExecutor {
  final Lock _lock = Lock();

  /// When a transaction is active in this executor and we're using statement
  /// based transactions (`BEGIN` and `COMMIT`), statements _not_ targetting the
  /// transaction need to wait for the transaction to be completed before being
  /// sent. This is also true for databases which otherwise aren't sequential.
  int _waitingTransactions = 0;

  QueryDelegate get impl;

  bool get isSequential => false;

  bool get logStatements => false;

  /// Used to provide better error messages when calling operations without
  /// calling [ensureOpen] before.
  bool _ensureOpenCalled = false;

  /// Whether this executor has explicitly been closed.
  bool _closed = false;

  bool _debugCheckIsOpen() {
    if (!_ensureOpenCalled) {
      throw StateError('''
Tried to run an operation without first calling QueryExecutor.ensureOpen()!

If you're seeing this exception from a drift database, it may indicate a bug in
drift itself. Please consider opening an issue with the stack trace and details
on how to reproduce this.''');
    }

    if (_closed) {
      throw StateError('''
This database or transaction runner has already been closed and may not be used
anymore.

If this is happening in a transaction, you might be using the transaction 
without awaiting every statement in it.''');
    }

    return true;
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    if (isSequential || _waitingTransactions > 0) {
      return _lock.synchronized(() {
        checkIfCancelled();
        return action();
      });
    } else {
      // support multiple operations in parallel, so just run right away
      return action();
    }
  }

  void _log(String sql, List<Object?> args) {
    if (logStatements) {
      driftRuntimeOptions.debugPrint('Drift: Sent $sql with args $args');
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) async {
    final result = await _synchronized(() {
      assert(_debugCheckIsOpen());
      _log(statement, args);
      return impl.runSelect(statement, args);
    });
    return result.asMap.toList();
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    return _synchronized(() {
      assert(_debugCheckIsOpen());
      _log(statement, args);
      return impl.runUpdate(statement, args);
    });
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) {
    return _synchronized(() {
      assert(_debugCheckIsOpen());
      _log(statement, args);
      return impl.runUpdate(statement, args);
    });
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    return _synchronized(() {
      assert(_debugCheckIsOpen());
      _log(statement, args);
      return impl.runInsert(statement, args);
    });
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) {
    return _synchronized(() {
      assert(_debugCheckIsOpen());
      final resolvedArgs = args ?? const [];
      _log(statement, resolvedArgs);
      return impl.runCustom(statement, resolvedArgs);
    });
  }

  @override
  Future<void> runBatched(BatchedStatements statements) {
    return _synchronized(() {
      assert(_debugCheckIsOpen());
      if (logStatements) {
        driftRuntimeOptions
            .debugPrint('Drift: Executing $statements in a batch');
      }
      return impl.runBatched(statements);
    });
  }
}

abstract class _TransactionExecutor extends _BaseExecutor
    implements TransactionExecutor {
  final DelegatedDatabase _db;

  _TransactionExecutor(this._db);

  void _checkCanOpen() {
    _ensureOpenCalled = true;

    if (_closed) {
      throw StateError(
          "A tranaction was used after being closed. Please check that you're "
          'awaiting all database operations inside a `transaction` block.');
    }
  }

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError("Nested transactions aren't supported.");
  }

  @override
  SqlDialect get dialect => _db.dialect;

  @override
  bool get logStatements => _db.logStatements;

  @override
  bool get isSequential => _db.isSequential;

  @override
  bool get supportsNestedTransactions => false;
}

/// A transaction implementation that sends `BEGIN` and `COMMIT` statements
/// over the direct database implementation and blocks the main database for the
/// duration of the transaction.
class _StatementBasedTransactionExecutor extends _TransactionExecutor {
  final NoTransactionDelegate _delegate;
  Completer<bool>? _opened;
  final Completer<void> _done = Completer();

  final _StatementBasedTransactionExecutor? _parent;

  final String _startCommand;
  final String _commitCommand;
  final String _rollbackCommand;

  // ignore: no_leading_underscores_for_local_identifiers
  _StatementBasedTransactionExecutor(super._db, this._delegate)
      : _startCommand = _delegate.start,
        _commitCommand = _delegate.commit,
        _rollbackCommand = _delegate.rollback,
        _parent = null;

  _StatementBasedTransactionExecutor.nested(
      _StatementBasedTransactionExecutor this._parent, int depth)
      : _delegate = _parent._delegate,
        _startCommand = 'SAVEPOINT s$depth',
        _commitCommand = 'RELEASE s$depth',
        _rollbackCommand = 'ROLLBACK TO s$depth',
        super(_parent._db);

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    _checkCanOpen();
    var opened = _opened;

    if (opened == null) {
      opened = _opened = Completer();
      // Block the main database or the parent transaction while this
      // transaction is active.
      final parent = _parent ?? _db;
      parent._waitingTransactions++;

      unawaited(parent._synchronized(() async {
        try {
          await runCustom(_startCommand);
          _db.delegate.isInTransaction = true;
          _opened!.complete(true);
        } catch (e, s) {
          _opened!.completeError(e, s);
        }

        // release the database lock after the transaction completes
        await _done.future;
      }).whenComplete(() => parent._waitingTransactions--));
    }

    return opened.future;
  }

  @override
  QueryDelegate get impl => _db.delegate;

  @override
  bool get supportsNestedTransactions => true;

  @override
  TransactionExecutor beginTransaction() {
    var ownDepth = 0;
    var ancestor = _parent;
    while (ancestor != null) {
      ownDepth++;
      ancestor = ancestor._parent;
    }

    return _StatementBasedTransactionExecutor.nested(this, ownDepth);
  }

  @override
  Future<void> send() async {
    // don't do anything if the transaction completes before it was opened
    if (!_ensureOpenCalled) return;

    await runCustom(_commitCommand, const []);
    _afterCommitOrRollback();
  }

  @override
  Future<void> rollback() async {
    if (!_ensureOpenCalled) return;

    try {
      await runCustom(_rollbackCommand, const []);
    } finally {
      // Note: When send() is called and throws an exception, we don't mark this
      // transaction is closed (as the commit should either be retried or the
      // whole transaction should be aborted).
      // When aborting fails too, something is seriously wrong already. Let's
      // at least make sure that we don't block the rest of the db by pretending
      // the transaction is still open.
      _afterCommitOrRollback();
    }
  }

  void _afterCommitOrRollback() {
    if (_parent == null) {
      _db.delegate.isInTransaction = false;
    }

    _done.complete();
    _closed = true;
  }
}

class _WrappingTransactionExecutor extends _TransactionExecutor {
  static final _artificialRollback =
      Exception('artificial exception to rollback the transaction');

  @override
  late QueryDelegate impl;
  final SupportedTransactionDelegate _delegate;

  // We're doing some async hacks for database implementations which manage
  // transactions for us (e.g. sqflite where we do `transaction((t) => ...)`)
  // and can only use the transaction in that callback.
  // Since drift's executor API works somewhat differently, our callback starts
  // a completer which we await in that callback. Outside of that callback, we
  // use the transaction and finally complete the completer with a bogus value
  // or with an exception if we want to commit or rollback the transaction.
  //
  // This works fine, but there's a rare problem since `ensureOpen` is called by
  // the first operation _inside_ drift's `transaction` block, NOT by the
  // transaction block itself. In particular, if that first operation is a
  // select, the zone calling `ensureOpen` is a cancellable error zone. This
  // means that, in the case of a rollback (sent from an outer zone), an error
  // event would cross error zone boundaries. This is blocked by Dart's async
  // implementation, which replaces it with an uncaught error handler.
  // We _do_ want to handle those errors though, so we make sure that this
  // wrapping hack in `ensureOpen` runs in the zone that created this
  // transaction runner and not in the zone that does the first operation.
  final Zone _createdIn = Zone.current;

  final Completer<void> _completerForCallback = Completer();
  Completer<void>? _opened, _finished;

  _WrappingTransactionExecutor(super.db, this._delegate);

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    _checkCanOpen();
    var opened = _opened;
    _ensureOpenCalled = true;

    if (opened == null) {
      _opened = opened = Completer();
      _createdIn.run(() {
        Future<void> launchTransaction() async {
          final result = _delegate.startTransaction((transaction) async {
            opened!.complete();
            impl = transaction;
            await _completerForCallback.future;
          });

          if (result is Future) {
            _finished = Completer()
              ..complete(
                // ignore: void_checks
                result
                    // Ignore the exception caused by [rollback] which may be
                    // rethrown by startTransaction
                    .onError<Exception>((error, stackTrace) => null,
                        test: (e) => e == _artificialRollback)
                    // Consider this transaction closed after the call completes
                    // This may happen without send/rollback being called in
                    // case there's an exception when opening the transaction.
                    .whenComplete(() => _closed = true),
              );
          }
        }

        if (_delegate.managesLockInternally) {
          return launchTransaction();
        } else {
          return _db._synchronized(launchTransaction);
        }
      });
    }

    // The opened completer is never completed if `startTransaction` throws
    // before our callback is invoked (probably becaue `BEGIN` threw an
    // exception). In that case, _finished will complete with that error though.
    return Future.any([opened.future, if (_finished != null) _finished!.future])
        .then((value) => true);
  }

  @override
  Future<void> send() async {
    // don't do anything if the transaction completes before it was opened
    if (_opened == null || _closed) return;

    _completerForCallback.complete();
    _closed = true;
    await _finished?.future;
  }

  @override
  Future<void> rollback() async {
    // Note: This may be called after send() if send() throws (that is, the
    // transaction can't be completed). But if completing fails, we assume that
    // the transaction will implicitly be rolled back the underlying connection
    // (it's not like we could explicitly roll it back, we only have one
    // callback to implement).
    if (_opened == null || _closed) return;

    _completerForCallback.completeError(_artificialRollback);
    _closed = true;
    await _finished?.future;
  }
}

/// A database engine (implements [QueryExecutor]) that delegates the relevant
/// work to a [DatabaseDelegate].
class DelegatedDatabase extends _BaseExecutor {
  /// The [DatabaseDelegate] to send queries to.
  final DatabaseDelegate delegate;

  @override
  bool logStatements;

  @override
  final bool isSequential;

  @override
  QueryDelegate get impl => delegate;

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  final Lock _openingLock = Lock();

  /// Constructs a delegated database by providing the [delegate].
  DelegatedDatabase(this.delegate,
      {bool? logStatements, this.isSequential = false})
      : logStatements = logStatements ?? false;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    final randomId = _getRandomNumber();
    print("Opening - $randomId - lock requested");
    return _openingLock.synchronized(() async {
      print("Opening - $randomId - lock obtained");

      try {
        if (_closed) {
          return Future.error(StateError(
              "Can't re-open a database after closing it. Please create a new "
              'database connection and open that instead.'));
        }

        final alreadyOpen = await delegate.isOpen;
        if (alreadyOpen) {
          _ensureOpenCalled = true;
          return true;
        }

        await delegate.open(user);
        _ensureOpenCalled = true;
        await _runMigrations(user);
        return true;
      } finally {
        print("Opening - $randomId - will release lock");
      }
    });
  }

  Future<void> _runMigrations(QueryExecutorUser user) async {
    final versionDelegate = delegate.versionDelegate;
    int? oldVersion;
    final currentVersion = user.schemaVersion;

    if (versionDelegate is NoVersionDelegate) {
      // this one is easy. There is no version mechanism, so we don't run any
      // migrations. Assume database is on latest version.
      oldVersion = user.schemaVersion;
    } else if (versionDelegate is OnOpenVersionDelegate) {
      // version has already been set during open
      oldVersion = await versionDelegate.loadSchemaVersion();
    } else if (versionDelegate is DynamicVersionDelegate) {
      oldVersion = await versionDelegate.schemaVersion;
      // Note: We only update the schema version after migrations ran
    } else {
      throw Exception('Invalid delegate: $delegate. The versionDelegate getter '
          'must not subclass DBVersionDelegate directly');
    }

    if (oldVersion == 0) {
      // some database implementations use version 0 to indicate that the
      // database was just created. We normalize that to null.
      oldVersion = null;
    }

    final openingDetails = OpeningDetails(oldVersion, currentVersion);
    await user.beforeOpen(_BeforeOpeningExecutor(this), openingDetails);

    if (versionDelegate is DynamicVersionDelegate &&
        (oldVersion == null || oldVersion < currentVersion)) {
      // set version now, after migrations ran successfully
      await versionDelegate.setSchemaVersion(currentVersion);
    }

    delegate.notifyDatabaseOpened(openingDetails);
  }

  @override
  TransactionExecutor beginTransaction() {
    final transactionDelegate = delegate.transactionDelegate;

    if (transactionDelegate is NoTransactionDelegate) {
      return _StatementBasedTransactionExecutor(this, transactionDelegate);
    } else if (transactionDelegate is SupportedTransactionDelegate) {
      return _WrappingTransactionExecutor(this, transactionDelegate);
    } else {
      throw StateError('Unknown transaction delegate: $transactionDelegate');
    }
  }

  @override
  Future<void> close() {
    final randomId = _getRandomNumber();
    print("Closing - $randomId - lock requested");
    return _openingLock.synchronized(() {
      print("Closing - $randomId - lock obtained");
      try {
        if (_ensureOpenCalled && !_closed) {
          _closed = true;

          // Make sure the other methods throw an exception when used after
          // close()
          _ensureOpenCalled = false;
          return delegate.close();
        } else {
          // User never attempted to open the database, so this is a no-op.
          return Future.value();
        }
      } finally {
        print("Closing - $randomId - will release lock");
      }
    });
  }
}

final Random _random = Random();

int _getRandomNumber() {
  return _random.nextInt(9999);
}

/// Inside a `beforeOpen` callback, all drift apis must be available. At the
/// same time, the `beforeOpen` callback must complete before any query sent
/// outside of a `beforeOpen` callback can run. We do this by introducing a
/// special executor that delegates all work to the original executor, but
/// without blocking on `ensureOpen`
class _BeforeOpeningExecutor extends _BaseExecutor {
  final DelegatedDatabase _base;

  _BeforeOpeningExecutor(this._base);

  @override
  TransactionExecutor beginTransaction() => _base.beginTransaction();

  @override
  Future<bool> ensureOpen(_) {
    _ensureOpenCalled = true;
    return Future.value(true);
  }

  @override
  QueryDelegate get impl => _base.impl;

  @override
  bool get logStatements => _base.logStatements;

  @override
  SqlDialect get dialect => _base.dialect;
}
