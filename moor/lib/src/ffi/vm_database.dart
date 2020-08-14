import 'dart:io';

import 'package:moor/backends.dart';
import 'package:sqlite3/sqlite3.dart';

import 'moor_ffi_functions.dart';

/// Signature of a function that can perform setup work on a [database] before
/// moor is fully ready.
///
/// This could be used to, for instance, set encryption keys for SQLCipher
/// implementations.
typedef DatabaseSetup = void Function(Database database);

/// A moor database that runs on the Dart VM.
class VmDatabase extends DelegatedDatabase {
  VmDatabase._(DatabaseDelegate delegate, bool logStatements)
      : super(delegate, isSequential: true, logStatements: logStatements);

  /// Creates a database that will store its result in the [file], creating it
  /// if it doesn't exist.
  ///
  /// If [logStatements] is true (defaults to `false`), generated sql statements
  /// will be printed before executing. This can be useful for debugging.
  /// The optional [setup] function can be used to perform a setup just after
  /// the database is opened, before moor is fully ready. This can be used to
  /// add custom user-defined sql functions or to provide encryption keys in
  /// SQLCipher implementations.
  factory VmDatabase(File file,
      {bool logStatements = false, DatabaseSetup setup}) {
    return VmDatabase._(_VmDelegate(file, setup), logStatements);
  }

  /// Creates an in-memory database won't persist its changes on disk.
  ///
  /// If [logStatements] is true (defaults to `false`), generated sql statements
  /// will be printed before executing. This can be useful for debugging.
  /// The optional [setup] function can be used to perform a setup just after
  /// the database is opened, before moor is fully ready. This can be used to
  /// add custom user-defined sql functions or to provide encryption keys in
  /// SQLCipher implementations.
  factory VmDatabase.memory({bool logStatements = false, DatabaseSetup setup}) {
    return VmDatabase._(_VmDelegate(null, setup), logStatements);
  }
}

class _VmDelegate extends DatabaseDelegate {
  Database _db;

  final File file;
  final DatabaseSetup setup;

  _VmDelegate(this.file, this.setup);

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen => Future.value(_db != null);

  @override
  Future<void> open(QueryExecutorUser user) async {
    if (file != null) {
      // Create the parent directory if it doesn't exist. sqlite will emit
      // confusing misuse warnings otherwise
      final dir = file.parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      _db = sqlite3.open(file.path);
    } else {
      _db = sqlite3.openInMemory();
    }
    _db.useMoorVersions();
    if (setup != null) {
      setup(_db);
    }
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
