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
    _db ??= Database(dbFile.absolute.path);
    return Future.value(true);
  }

  @override
  Future<void> runCustom(String statement) {
    _logStmt(statement, const []);
    _db.execute(statement);
    return Future.value();
  }

  Future<int> _executeWithArgs(String statement, List<dynamic> args) {
    _logStmt(statement, args);
    _db.execute(statement, params: args);
    return Future.value(_db.changes());
  }

  @override
  Future<int> runDelete(String statement, List<dynamic> args) {
    return _executeWithArgs(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List<dynamic> args) {
    return _executeWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<dynamic> args) {
    _logStmt(statement, args);
    _db.execute(statement, params: args);
    return Future.value(_db.lastInsertId());
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List<dynamic> args) {
    if (args.isNotEmpty) {
      throw UnsupportedError(
          'Select statements with variables are not yet supported.');
    }
    _logStmt(statement, args);
    _db.query(statement);
    // todo parse rows
    return Future.value([]);
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
