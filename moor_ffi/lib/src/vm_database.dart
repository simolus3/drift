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

  /// Creates a database won't persist its changes on disk.
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
  Future<void> open([GeneratedDatabase db]) {
    if (file != null) {
      _db = Database.openFile(file);
    } else {
      _db = Database.memory();
    }
    versionDelegate = _VmVersionDelegate(_db);
    return Future.value();
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

  void _runWithArgs(String statement, List<dynamic> args) {
    if (args.isEmpty) {
      _db.execute(statement);
    } else {
      _db.prepare(statement)
        ..execute(args)
        ..close();
    }
  }

  @override
  Future<void> runCustom(String statement, List args) {
    _runWithArgs(statement, args);
    return Future.value();
  }

  @override
  Future<int> runInsert(String statement, List args) {
    _runWithArgs(statement, args);
    return Future.value(_db.lastInsertId);
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    _runWithArgs(statement, args);
    return Future.value(_db.updatedRows);
  }

  @override
  Future<QueryResult> runSelect(String statement, List args) {
    final stmt = _db.prepare(statement);
    final result = stmt.select(args);
    stmt.close();

    return Future.value(QueryResult(result.columnNames, result.rows));
  }
}

class _VmVersionDelegate extends DynamicVersionDelegate {
  final Database database;

  _VmVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion => Future.value(database.userVersion);

  @override
  Future<void> setSchemaVersion(int version) {
    database.userVersion = version;
    return Future.value();
  }
}
