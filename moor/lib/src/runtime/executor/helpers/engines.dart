import 'dart:async';

import 'package:moor/moor.dart';
import 'package:pedantic/pedantic.dart';
import 'package:synchronized/synchronized.dart';

import 'delegates.dart';

mixin _ExecutorWithQueryDelegate on QueryExecutor {
  QueryDelegate get impl;

  bool get isSequential => false;
  bool get logStatements => false;
  final Lock _lock = Lock();

  Future<T> _synchronized<T>(FutureOr<T> Function() action) async {
    if (isSequential) {
      return await _lock.synchronized(action);
    } else {
      // support multiple operations in parallel, so just run right away
      return await action();
    }
  }

  void _log(String sql, List<dynamic> args) {
    if (logStatements) {
      print('Moor: Sent $sql with args $args');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List args) async {
    final result = await _synchronized(() {
      _log(statement, args);
      return impl.runSelect(statement, args);
    });
    return result.asMap.toList();
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    return _synchronized(() {
      _log(statement, args);
      return impl.runUpdate(statement, args);
    });
  }

  @override
  Future<int> runDelete(String statement, List args) {
    return _synchronized(() {
      _log(statement, args);
      return impl.runUpdate(statement, args);
    });
  }

  @override
  Future<int> runInsert(String statement, List args) {
    return _synchronized(() {
      _log(statement, args);
      return impl.runInsert(statement, args);
    });
  }

  @override
  Future<void> runCustom(String statement) {
    return _synchronized(() {
      _log(statement, const []);
      return impl.runCustom(statement, const []);
    });
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
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
  QueryDelegate impl;

  @override
  bool get isSequential => _db.isSequential;

  @override
  bool get logStatements => _db.logStatements;

  final Completer<void> _sendCalled = Completer();
  Completer<bool> _openingCompleter;

  String _sendOnCommit;

  Future get completed => _sendCalled.future;

  _TransactionExecutor(this._db);

  @override
  TransactionExecutor beginTransaction() {
    throw Exception("Nested transactions aren't supported");
  }

  @override
  Future<bool> ensureOpen() async {
    if (_openingCompleter != null) {
      return await _openingCompleter.future;
    }

    _openingCompleter = Completer();

    final transactionManager = _db.delegate.transactionDelegate;
    final transactionStarted = Completer();

    if (transactionManager is NoTransactionDelegate) {
      assert(
          _db.isSequential,
          'When using the default NoTransactionDelegate, the database must be'
          'sequential.');
      // run all the commands on the main database, which we block while the
      // transaction is running.
      unawaited(_db._synchronized(() async {
        impl = _db.delegate;
        await impl.runCustom(transactionManager.start, const []);
        _sendOnCommit = transactionManager.commit;

        transactionStarted.complete();

        // release the database lock after the transaction completes
        await _sendCalled.future;
      }));
    } else if (transactionManager is SupportedTransactionDelegate) {
      transactionManager.startTransaction((transaction) async {
        impl = transaction;
        transactionStarted.complete();

        // this callback must be running as long as the transaction, so we do
        // that until send() was called.
        await _sendCalled.future;
      });
    } else {
      throw Exception('Invalid delegate: Has unknown transaction delegate');
    }

    await transactionStarted.future;
    _openingCompleter.complete(true);
    return true;
  }

  @override
  Future<void> send() async {
    if (_sendOnCommit != null) {
      await impl.runCustom(_sendOnCommit, const []);
    }

    _sendCalled.complete();
  }
}

class _BeforeOpeningExecutor extends QueryExecutor
    with _ExecutorWithQueryDelegate {
  final DelegatedDatabase db;

  @override
  QueryDelegate get impl => db.delegate;

  @override
  bool get isSequential => db.isSequential;

  @override
  bool get logStatements => db.logStatements;

  _BeforeOpeningExecutor(this.db);

  @override
  TransactionExecutor beginTransaction() {
    throw Exception(
        "Transactions can't be started in the before open callback");
  }

  @override
  Future<bool> ensureOpen() {
    return Future.value(true);
  }
}

class DelegatedDatabase extends QueryExecutor with _ExecutorWithQueryDelegate {
  final DatabaseDelegate delegate;
  Completer<bool> _openingCompleter;

  @override
  final bool logStatements;
  @override
  final bool isSequential;

  @override
  QueryDelegate get impl => delegate;

  DelegatedDatabase(this.delegate,
      {this.logStatements = false, this.isSequential = false});

  @override
  Future<bool> ensureOpen() async {
    // if we're already opening the database or if its already open, return that
    // status
    if (_openingCompleter != null) {
      return _openingCompleter.future;
    }

    final alreadyOpen = await delegate.isOpen;
    if (alreadyOpen) return true;

    // ignore: invariant_booleans
    if (_openingCompleter != null) {
      return _openingCompleter.future;
    }

    // not already open or opening. Open the database now!
    _openingCompleter = Completer();
    await delegate.open(databaseInfo);
    await _runMigrations();

    _openingCompleter.complete(true);
    _openingCompleter = null;
    return true;
  }

  Future<void> _runMigrations() async {
    final versionDelegate = delegate.versionDelegate;
    int oldVersion;
    final currentVersion = databaseInfo.schemaVersion;

    if (versionDelegate is NoVersionDelegate) {
      // this one is easy. There is no version mechanism, so we don't run any
      // migrations. Assume database is on latest version.
      oldVersion = databaseInfo.schemaVersion;
    } else if (versionDelegate is OnOpenVersionDelegate) {
      // version has already been set during open
      oldVersion = await versionDelegate.loadSchemaVersion();
    } else if (versionDelegate is DynamicVersionDelegate) {
      // set version now
      oldVersion = await versionDelegate.schemaVersion;
      await versionDelegate.setSchemaVersion(currentVersion);
    } else {
      throw Exception('Invalid delegate: $delegate. The versionDelegate getter '
          'must not subclass DBVersionDelegate directly');
    }

    if (oldVersion == 0) {
      // some database implementations use version 0 to indicate that the
      // database was just created. We normalize that to null.
      oldVersion = null;
    }

    final dbCreated = oldVersion == null;

    if (dbCreated) {
      await databaseInfo.handleDatabaseCreation(executor: runCustom);
    } else if (oldVersion != currentVersion) {
      await databaseInfo.handleDatabaseVersionChange(
          executor: runCustom, from: oldVersion, to: currentVersion);
    }

    await _runBeforeOpen(OpeningDetails(oldVersion, currentVersion));
  }

  @override
  TransactionExecutor beginTransaction() {
    return _TransactionExecutor(this);
  }

  Future<void> _runBeforeOpen(OpeningDetails d) {
    return databaseInfo.beforeOpenCallback(_BeforeOpeningExecutor(this), d);
  }
}
