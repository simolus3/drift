part of 'package:moor/moor_web.dart';

class _DbState {
  final String name;
  final bool logStatements;
  final Lock lock = Lock();

  SqlJsDatabase db;

  _DbState(this.name, this.logStatements);
}

abstract class _DatabaseUser extends QueryExecutor {
  final _DbState _state;

  String get name => _state.name;
  bool get logStatements => _state.logStatements;
  SqlJsDatabase get _db => _state.db;

  bool get _bypassLock => false;

  String get _persistenceKey => 'moor_db_str_$name';

  _DatabaseUser(this._state);

  Future<T> _synchronized<T>(FutureOr<T> computation()) async {
    final lock = _state.lock;
    if (_bypassLock) {
      return await computation();
    }

    return await lock.synchronized(computation);
  }

  // todo base64 works, but is very slow. Figure out why bin2str is broken

  Uint8List _restoreDb() {
    final raw = window.localStorage[_persistenceKey];
    if (raw != null) {
      return base64.decode(raw);
    }
    return null;
  }

  void _storeDb() {
    final data = _db.export();
    final binStr = base64.encode(data);
    window.localStorage[_persistenceKey] = binStr;
  }

  @tryInline
  void _log(String sql, List<dynamic> variables) {
    if (logStatements) {
      print('[moor_web]: Running $sql with bound args: $variables');
    }
  }

  /// Executes [sql] with the bound [variables], and ignores the result.
  Future _runSimple(String sql, List<dynamic> variables) {
    return _synchronized(() {
      _log(sql, variables);
      _db.runWithArgs(sql, variables);
    });
  }

  Future<void> _runWithoutArgs(String query) {
    return _synchronized(() {
      _db.run(query);
    });
  }

  @override
  Future<void> runCustom(String statement) {
    return _runWithoutArgs(statement);
  }

  @override
  Future<int> runDelete(String statement, List args) {
    _runSimple(statement, args);
    return _handlePotentialUpdate();
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    _runSimple(statement, args);
    return _handlePotentialUpdate();
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) async {
    await _synchronized(() {
      for (var stmt in statements) {
        final prepared = _db.prepare(stmt.sql);

        for (var args in stmt.variables) {
          prepared.executeWith(args);
        }
      }
    });

    await _handlePotentialUpdate();
  }

  /// Saves the database if the last statement changed rows. As a side-effect,
  /// saving the database resets the `last_insert_id` counter in sqlite.
  Future<int> _handlePotentialUpdate() {
    final modified = _db.lastModifiedRows();
    if (modified > 0) {
      _storeDb();
    }
    return Future.value(modified);
  }

  @override
  Future<int> runInsert(String statement, List args) async {
    await _runSimple(statement, args);
    final insertId = _db.lastInsertId();
    await _handlePotentialUpdate();
    return insertId;
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(String statement, List args) {
    _log(statement, args);
    return _synchronized(() async {
      // todo at least for stream queries we should cache prepared statements.
      final stmt = _db.prepare(statement)..executeWith(args);

      List<String> columnNames;
      final rows = <Map<String, dynamic>>[];

      while (stmt.step()) {
        columnNames ??= stmt.columnNames();
        final row = stmt.currentRow();

        rows.add({for (var i = 0; i < row.length; i++) columnNames[i]: row[i]});
      }

      stmt.free();
      return rows;
    });
  }
}

/// Experimental moor backend for the web. To use this platform, you need to
/// include the latest version of `sql.js` in your html.
class WebDatabase extends _DatabaseUser {
  Completer<bool> _openingCompleter;

  WebDatabase(String name, {bool logStatements = false})
      : super(_DbState(name, logStatements));

  @override
  TransactionExecutor beginTransaction() {
    final transactionReady = Completer<bool>();
    final executor = _TransactionExecutor(_state, transactionReady.future);

    _synchronized(() async {
      // we have the lock -> start the transaction
      transactionReady.complete(true);
      // wait until the transaction is done, then release the lock
      await executor.completed;

      if (executor._needsSave) {
        _storeDb();
      }
    });

    return executor;
  }

  @override
  Future<bool> ensureOpen() async {
    // sync mechanism to make sure _openInternal is only called once
    if (_db != null) {
      return true;
    } else if (_openingCompleter != null) {
      return _openingCompleter.future;
    } else {
      _openingCompleter = Completer();
      await _openInternal();
      _openingCompleter.complete(true);
      return true;
    }
  }

  Future<void> _openInternal() async {
    // We don't get information about the database version from sql.js, so we
    // create another database just to manage versions.
    if (!IdbFactory.supported) {
      throw UnsupportedError("This browser doesn't support IndexedDb");
    }

    int version;
    var upgradeNeeded = false;

    final db = await window.indexedDB.open(
      name,
      version: databaseInfo.schemaVersion,
      onUpgradeNeeded: (event) {
        upgradeNeeded = true;
        version = event.oldVersion;
      },
    );
    db.close();

    final module = await initSqlJs();
    final restored = _restoreDb();
    _state.db = module.createDatabase(restored);

    if (upgradeNeeded) {
      if (version == null || version < 1) {
        await databaseInfo.handleDatabaseCreation(executor: _runWithoutArgs);
      } else {
        await databaseInfo.handleDatabaseVersionChange(
            executor: _runWithoutArgs,
            from: version,
            to: databaseInfo.schemaVersion);
      }
    }

    await _synchronized(() {
      return databaseInfo.beforeOpenCallback(_BeforeOpenExecutor(_state),
          OpeningDetails(version, databaseInfo.schemaVersion));
    });

    if (upgradeNeeded) {
      // assume that a schema version was written in an upgrade => save db
      _storeDb();
    }
  }
}

class _BeforeOpenExecutor extends _DatabaseUser {
  _BeforeOpenExecutor(_DbState state) : super(state);

  @override
  final bool _bypassLock = true;

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError(
        "Transactions aren't supported in the before open callback");
  }

  @override
  Future<bool> ensureOpen() => Future.value(true);
}

class _TransactionExecutor extends _DatabaseUser
    implements TransactionExecutor {
  _TransactionExecutor(_DbState state, this._openingFuture) : super(state);

  @override
  final bool _bypassLock = true;

  final Future<bool> _openingFuture;
  bool _sentBeginTransaction = false;

  final Completer<void> _completer = Completer();
  Future<void> get completed => _completer.future;
  bool _needsSave = false;

  @override
  void _storeDb() {
    // no-op inside a transaction. Store the database when we it's done!
    _needsSave = true;
  }

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError('Cannot have nested transactions');
  }

  @override
  Future<bool> ensureOpen() async {
    await _openingFuture;
    if (!_sentBeginTransaction) {
      _db.run('BEGIN TRANSACTION');
      _sentBeginTransaction = true;
    }
    return Future.value(true);
  }

  @override
  Future<void> send() {
    _db.run('COMMIT TRANSACTION;');
    _completer.complete();
    return Future.value();
  }
}
