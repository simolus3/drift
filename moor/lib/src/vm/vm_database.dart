part of 'package:moor/moor_vm.dart';

abstract class _DatabaseUser extends QueryExecutor {
  final bool logStatements;
  final File dbFile;

  Database _db;

  _DatabaseUser(this.logStatements, this.dbFile);

  void _logStmt(String statement, List<dynamic> args) {
    if (logStatements) {
      print('Executing $statement with variables $args');
    }
  }

  @override
  Future<void> runCustom(String statement) {
    _logStmt(statement, const []);
    _db.execute(statement);
    return Future.value();
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
    return _runAndReturnAffected(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List<dynamic> args) {
    return _runAndReturnAffected(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<dynamic> args) {
    _runWithArgs(statement, args);
    return Future.value(_db.lastInsertId);
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List<dynamic> args) {
    _logStmt(statement, args);
    final stmt = _db.prepare(statement);
    final result = stmt.select(args);
    stmt.close();

    return Future.value(result.toList());
  }

  @override
  Future<void> close() {
    _db?.close();
    return Future.value();
  }
}

class VMDatabase extends _DatabaseUser {
  VMDatabase(File file, {bool logStatements = false})
      : super(logStatements, file);

  VMDatabase.memory({bool logStatements = false}) : super(logStatements, null);

  @override
  Future<bool> ensureOpen() async {
    if (_db == null) {
      _db = _openInternal();
      await _runMigrations();
    }
    return true;
  }

  Database _openInternal() {
    if (dbFile == null) {
      return Database.memory();
    } else {
      return Database.openFile(dbFile);
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
  }

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError('Transactions are not yet supported on the Dart VM');
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
