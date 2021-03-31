import 'dart:async';

import 'package:moor/moor.dart';
import 'package:moor/src/utils/synchronized.dart';
import 'package:pedantic/pedantic.dart';

import '../../cancellation_zone.dart';
import 'delegates.dart';

mixin _ExecutorWithQueryDelegate on QueryExecutor {
  final Lock _lock = Lock();

  QueryDelegate get impl;

  bool get isSequential => false;

  bool get logStatements => false;

  /// Used to provide better error messages when calling operations without
  /// calling [ensureOpen] before.
  bool _ensureOpenCalled = false;

  Future<T> _synchronized<T>(Future<T> Function() action) {
    if (isSequential) {
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
      print('Moor: Sent $sql with args $args');
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) async {
    assert(_ensureOpenCalled);
    final result = await _synchronized(() {
      _log(statement, args);
      return impl.runSelect(statement, args);
    });
    return result.asMap.toList();
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    assert(_ensureOpenCalled);
    return _synchronized(() {
      _log(statement, args);
      return impl.runUpdate(statement, args);
    });
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) {
    assert(_ensureOpenCalled);
    return _synchronized(() {
      _log(statement, args);
      return impl.runUpdate(statement, args);
    });
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    assert(_ensureOpenCalled);
    return _synchronized(() {
      _log(statement, args);
      return impl.runInsert(statement, args);
    });
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) {
    assert(_ensureOpenCalled);
    return _synchronized(() {
      final resolvedArgs = args ?? const [];
      _log(statement, resolvedArgs);
      return impl.runCustom(statement, resolvedArgs);
    });
  }

  @override
  Future<void> runBatched(BatchedStatements statements) {
    assert(_ensureOpenCalled);
    return _synchronized(() {
      if (logStatements) {
        print('Moor: Executing $statements in a batch');
      }
      return impl.runBatched(statements);
    });
  }
}

class _TransactionExecutor extends TransactionExecutor
    with _ExecutorWithQueryDelegate {
  final DelegatedDatabase _db;

  @override
  late QueryDelegate impl;

  @override
  bool get isSequential => _db.isSequential;

  @override
  bool get logStatements => _db.logStatements;

  final Completer<void> _sendCalled = Completer();
  Completer<bool>? _openingCompleter;

  String? _sendOnCommit;
  String? _sendOnRollback;

  Future get completed => _sendCalled.future;
  bool _sendFakeErrorOnRollback = false;

  bool _done = false;

  _TransactionExecutor(this._db);

  @override
  TransactionExecutor beginTransaction() {
    throw Exception("Nested transactions aren't supported");
  }

  @override
  Future<bool> ensureOpen(_) async {
    assert(
      !_done,
      'Transaction was used after it completed. Are you missing an await '
      'somewhere?',
    );

    _ensureOpenCalled = true;
    if (_openingCompleter != null) {
      return await _openingCompleter!.future;
    }

    _openingCompleter = Completer();

    final transactionManager = _db.delegate.transactionDelegate;
    final transactionStarted = Completer();

    if (transactionManager is NoTransactionDelegate) {
      assert(
          _db.isSequential,
          'When using the default NoTransactionDelegate, the database must be '
          'sequential.');
      // run all the commands on the main database, which we block while the
      // transaction is running.
      unawaited(_db._synchronized(() async {
        impl = _db.delegate;
        await runCustom(transactionManager.start, const []);
        _db.delegate.isInTransaction = true;

        _sendOnCommit = transactionManager.commit;
        _sendOnRollback = transactionManager.rollback;

        transactionStarted.complete();

        // release the database lock after the transaction completes
        await _sendCalled.future;
      }));
    } else if (transactionManager is SupportedTransactionDelegate) {
      transactionManager.startTransaction((transaction) async {
        impl = transaction;
        // specs say that the db implementation will perform a rollback when
        // this future completes with an error.
        _sendFakeErrorOnRollback = true;
        transactionStarted.complete();

        // this callback must be running as long as the transaction, so we do
        // that until send() was called.
        await _sendCalled.future;
      });
    } else {
      throw Exception('Invalid delegate: Has unknown transaction delegate');
    }

    await transactionStarted.future;
    _openingCompleter!.complete(true);
    return true;
  }

  @override
  Future<void> send() async {
    // don't do anything if the transaction completes before it was opened
    if (_openingCompleter == null) return;

    if (_sendOnCommit != null) {
      await runCustom(_sendOnCommit!, const []);
      _db.delegate.isInTransaction = false;
    }

    _sendCalled.complete();
    _done = true;
  }

  @override
  Future<void> rollback() async {
    // don't do anything if the transaction completes before it was opened
    if (_openingCompleter == null) return;

    if (_sendOnRollback != null) {
      await runCustom(_sendOnRollback!, const []);
      _db.delegate.isInTransaction = false;
    }

    if (_sendFakeErrorOnRollback) {
      _sendCalled.completeError(
          Exception('artificial exception to rollback the transaction'));
    } else {
      _sendCalled.complete();
    }

    _done = true;
  }
}

/// A database engine (implements [QueryExecutor]) that delegates the relevant
/// work to a [DatabaseDelegate].
class DelegatedDatabase extends QueryExecutor with _ExecutorWithQueryDelegate {
  /// The [DatabaseDelegate] to send queries to.
  final DatabaseDelegate delegate;

  @override
  bool logStatements;
  @override
  final bool isSequential;

  @override
  QueryDelegate get impl => delegate;

  @override
  SqlDialect get dialect => delegate.dialect;

  final Lock _openingLock = Lock();

  /// Constructs a delegated database by providing the [delegate].
  DelegatedDatabase(this.delegate,
      {bool? logStatements, this.isSequential = false})
      : logStatements = logStatements ?? false;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    _ensureOpenCalled = true;
    return _openingLock.synchronized(() async {
      final alreadyOpen = await delegate.isOpen;
      if (alreadyOpen) {
        return true;
      }

      await delegate.open(user);
      await _runMigrations(user);
      return true;
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

    if (versionDelegate is DynamicVersionDelegate) {
      // set version now, after migrations ran successfully
      await versionDelegate.setSchemaVersion(currentVersion);
    }

    delegate.notifyDatabaseOpened(openingDetails);
  }

  @override
  TransactionExecutor beginTransaction() {
    return _TransactionExecutor(this);
  }

  @override
  Future<void> close() {
    if (_ensureOpenCalled) {
      return delegate.close();
    } else {
      // User never attempted to open the database, so this is a no-op.
      return Future.value();
    }
  }
}

/// Inside a `beforeOpen` callback, all moor apis must be available. At the same
/// time, the `beforeOpen` callback must complete before any query sent outside
/// of a `beforeOpen` callback can run. We do this by introducing a special
/// executor that delegates all work to the original executor, but without
/// blocking on `ensureOpen`
class _BeforeOpeningExecutor extends QueryExecutor
    with _ExecutorWithQueryDelegate {
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
}
