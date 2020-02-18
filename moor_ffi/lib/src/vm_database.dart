part of 'package:moor_ffi/moor_ffi.dart';

/// A moor database that runs on the Dart VM.
class VmDatabase extends DelegatedDatabase {
  VmDatabase._(DatabaseDelegate delegate, bool logStatements)
      : super(delegate, isSequential: true, logStatements: logStatements);

  /// Creates a database that will store its result in the [file], creating it
  /// if it doesn't exist.
  factory VmDatabase(File file, {bool logStatements = false}) {
    return VmDatabase._(_VmDelegate(file), logStatements);
  }

  /// Creates an in-memory database won't persist its changes on disk.
  factory VmDatabase.memory({bool logStatements = false}) {
    return VmDatabase._(_VmDelegate(null), logStatements);
  }
}

class _VmDelegate extends DatabaseDelegate {
  Database _db;

  final File file;

  _VmDelegate(this.file);

  @override
  final TransactionDelegate transactionDelegate = const NoTransactionDelegate();

  @override
  DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen => Future.value(_db != null);

  @override
  Future<void> open([GeneratedDatabase db]) async {
    if (file != null) {
      _db = Database.openFile(file);
    } else {
      _db = Database.memory();
    }
    _db.enableMathematicalFunctions();
    versionDelegate = _VmVersionDelegate(_db);
    return Future.value();
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) async {
    for (final stmt in statements) {
      final prepared = _db.prepare(stmt.sql);
      stmt.variables.forEach(prepared.execute);

      prepared.close();
    }

    return Future.value();
  }

  Future _runWithArgs(String statement, List<dynamic> args) async {
    if (args.isEmpty) {
      _db.execute(statement);
    } else {
      final stmt = _db.prepare(statement);
      stmt.execute(args);
      stmt.close();
    }
  }

  @override
  Future<void> runCustom(String statement, List args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List args) async {
    await _runWithArgs(statement, args);
    return _db.getLastInsertId();
  }

  @override
  Future<int> runUpdate(String statement, List args) async {
    await _runWithArgs(statement, args);
    return _db.getUpdatedRows();
  }

  @override
  Future<QueryResult> runSelect(String statement, List args) async {
    final stmt = _db.prepare(statement);
    final result = stmt.select(args);
    stmt.close();

    return Future.value(QueryResult(result.columnNames, result.rows));
  }

  @override
  Future<void> close() async {
    _db.close();
  }
}

class _VmVersionDelegate extends DynamicVersionDelegate {
  final Database database;

  _VmVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion => Future.value(database.userVersion());

  @override
  Future<void> setSchemaVersion(int version) {
    database.setUserVersion(version);
    return Future.value();
  }
}
