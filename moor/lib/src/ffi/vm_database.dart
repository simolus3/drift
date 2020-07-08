import 'dart:io';

import 'package:moor/backends.dart';
import 'package:sqlite3/sqlite3.dart';

import 'moor_ffi_functions.dart';

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
  Future<void> open(QueryExecutorUser user) async {
    if (file != null) {
      _db = sqlite3.open(file.path);
    } else {
      _db = sqlite3.openInMemory();
    }
    _db.useMoorVersions();
    versionDelegate = _VmVersionDelegate(_db);
    return Future.value();
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final prepared = [
      for (final stmt in statements.statements) _db.prepare(stmt),
    ];

    for (final application in statements.arguments) {
      final stmt = prepared[application.statementIndex];

      stmt.execute(application.arguments);
    }

    for (final stmt in prepared) {
      stmt.dispose();
    }

    return Future.value();
  }

  Future _runWithArgs(String statement, List<dynamic> args) async {
    if (args.isEmpty) {
      _db.execute(statement);
    } else {
      final stmt = _db.prepare(statement);
      stmt.execute(args);
      stmt.dispose();
    }
  }

  @override
  Future<void> runCustom(String statement, List args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List args) async {
    await _runWithArgs(statement, args);
    return _db.lastInsertRowId;
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
    stmt.dispose();

    return Future.value(QueryResult.fromRows(result.toList()));
  }

  @override
  Future<void> close() async {
    _db.dispose();
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
