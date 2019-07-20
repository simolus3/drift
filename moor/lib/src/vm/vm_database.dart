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
  Future<bool> ensureOpen() {
    _db ??= _openInternal();

    return Future.value(true);
  }

  Database _openInternal() {
    if (dbFile == null) {
      return Database.memory();
    } else {
      return Database.openFile(dbFile);
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

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError('Transactions are not yet supported on the Dart VM');
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
    throw UnsupportedError(
        'Batched inserts are not yet supported on the Dart VM');
  }
}
