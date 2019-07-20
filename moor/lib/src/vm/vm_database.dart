part of 'package:moor/moor_vm.dart';

class _DbState {
  final bool logStatements;
  final File file;
  final Lock lock = Lock();

  Database db;

  _DbState(this.logStatements, this.file);
}

abstract class _DatabaseUser extends QueryExecutor {
  final _DbState _state;

  bool get _bypassLock => false;
  Database get _db => _state.db;

  _DatabaseUser(this._state);

  void _logStmt(String statement, List<dynamic> args) {
    if (_state.logStatements) {
      print('Executing $statement with variables $args');
    }
  }

  Future<T> _synchronized<T>(FutureOr<T> computation()) async {
    final lock = _state.lock;
    if (_bypassLock) {
      return await computation();
    }

    return await lock.synchronized(computation);
  }

  @override
  Future<void> runCustom(String statement) {
    return _synchronized(() {
      _logStmt(statement, const []);
      _db.execute(statement);
    });
  }

  void _runWithArgs(String statement, List<dynamic> args) {
    _logStmt(statement, args);

    if (args.isEmpty) {
      _db.execute(statement);
    } else {
      _db.prepare(statement)
        ..execute(args)
        ..close();
    }
  }

  Future<int> _runAndReturnAffected(String statement, List<dynamic> args) {
    _runWithArgs(statement, args);
    return Future.value(_db.updatedRows);
  }

  @override
  Future<int> runDelete(String statement, List<dynamic> args) {
    return _synchronized(() {
      return _runAndReturnAffected(statement, args);
    });
  }

  @override
  Future<int> runUpdate(String statement, List<dynamic> args) {
    return _synchronized(() {
      return _runAndReturnAffected(statement, args);
    });
  }

  @override
  Future<int> runInsert(String statement, List<dynamic> args) {
    return _synchronized(() {
      _runWithArgs(statement, args);
      return Future.value(_db.lastInsertId);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List<dynamic> args) {
    return _synchronized(() {
      _logStmt(statement, args);
      final stmt = _db.prepare(statement);
      final result = stmt.select(args);
      stmt.close();

      return Future.value(result.toList());
    });
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
    for (var stmt in statements) {
      final prepared = _db.prepare(stmt.sql);

      for (var boundVars in stmt.variables) {
        prepared.execute(boundVars);
      }

      prepared.close();
    }

    return Future.value();
  }
}

class VMDatabase extends _DatabaseUser {
  VMDatabase(File file, {bool logStatements = false})
      : super(_DbState(logStatements, file));

  VMDatabase.memory({bool logStatements = false})
      : this(null, logStatements: logStatements);

  @override
  Future<bool> ensureOpen() async {
    if (_db == null) {
      _state.db = _openInternal();
      await _runMigrations();
    }
    return true;
  }

  Database _openInternal() {
    if (_state.file == null) {
      return Database.memory();
    } else {
      return Database.openFile(_state.file);
    }
  }

  Future _runMigrations() async {
    final current = _db.userVersion;
    final target = databaseInfo.schemaVersion;

    if (current == 0) {
      await databaseInfo.handleDatabaseCreation(executor: runCustom);
    } else if (current < target) {
      await databaseInfo.handleDatabaseVersionChange(
          executor: null, from: current, to: target);
    }

    _db.userVersion = target;

    await _synchronized(() {
      databaseInfo.beforeOpenCallback(
          _BeforeOpenExecutor(_state), OpeningDetails(current, target));
    });
  }

  @override
  Future<void> close() {
    _db?.close();
    return Future.value();
  }

  @override
  TransactionExecutor beginTransaction() {
    final transactionReady = Completer<bool>();
    final executor = _TransactionExecutor(_state, transactionReady.future);

    _synchronized(() async {
      // we have the lock, so start the transaction
      transactionReady.complete(true);
      await executor.completed;
    });

    return executor;
  }
}

class _BeforeOpenExecutor extends _DatabaseUser with BeforeOpenMixin {
  @override
  final bool _bypassLock = true;
  _BeforeOpenExecutor(_DbState state) : super(state);
}

class _TransactionExecutor extends _DatabaseUser with TransactionExecutor {
  @override
  final bool _bypassLock = true;
  final Future<bool> _openingFuture;
  bool _sentBeginTransaction = false;

  final Completer<void> _completer = Completer();
  Future<void> get completed => _completer.future;

  _TransactionExecutor(_DbState state, this._openingFuture) : super(state);

  @override
  Future<bool> ensureOpen() async {
    await _openingFuture;
    if (!_sentBeginTransaction) {
      _db.execute('BEGIN TRANSACTION');
      _sentBeginTransaction = true;
    }
    return Future.value(true);
  }

  @override
  Future<void> send() {
    _db.execute('COMMIT TRANSACTION;');
    _completer.complete();
    return Future.value();
  }
}
