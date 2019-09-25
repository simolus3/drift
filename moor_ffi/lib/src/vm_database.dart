part of 'package:moor_ffi/moor_ffi.dart';

/// A moor database that runs on the Dart VM.
class VmDatabase extends DelegatedDatabase {
  VmDatabase._(DatabaseDelegate delegate, bool logStatements)
      : super(delegate, isSequential: true, logStatements: logStatements);

  /// Creates a database that will store its result in the [file], creating it
  /// if it doesn't exist.
  ///
  /// If [background] is enabled (defaults to false), the database will be
  /// opened on a background isolate. This is much slower, but reduces work on
  /// the UI thread.
  factory VmDatabase(File file,
      {bool logStatements = false, bool background = false}) {
    return VmDatabase._(_VmDelegate(file, background), logStatements);
  }

  /// Creates an in-memory database won't persist its changes on disk.
  factory VmDatabase.memory({bool logStatements = false}) {
    return VmDatabase._(_VmDelegate(null, false), logStatements);
  }
}

class _VmDelegate extends DatabaseDelegate {
  BaseDatabase _db;

  final File file;
  final bool background;

  _VmDelegate(this.file, this.background);

  @override
  final TransactionDelegate transactionDelegate = const NoTransactionDelegate();

  @override
  DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen => Future.value(_db != null);

  @override
  Future<void> open([GeneratedDatabase db]) async {
    if (file != null) {
      if (background) {
        _db = await IsolateDb.openFile(file);
      } else {
        _db = Database.openFile(file);
      }
    } else {
      assert(
          !background,
          "moor_ffi doesn't support in-memory databases on a background "
          'isolate');
      _db = Database.memory();
    }
    versionDelegate = _VmVersionDelegate(_db);
    return Future.value();
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) async {
    for (var stmt in statements) {
      final prepared = await _db.prepare(stmt.sql);

      for (var boundVars in stmt.variables) {
        await prepared.execute(boundVars);
      }

      prepared.close();
    }

    return Future.value();
  }

  Future _runWithArgs(String statement, List<dynamic> args) async {
    if (args.isEmpty) {
      await _db.execute(statement);
    } else {
      final stmt = await _db.prepare(statement);
      await stmt.execute(args);
      await stmt.close();
    }
  }

  @override
  Future<void> runCustom(String statement, List args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List args) async {
    await _runWithArgs(statement, args);
    return await _db.getLastInsertId();
  }

  @override
  Future<int> runUpdate(String statement, List args) async {
    await _runWithArgs(statement, args);
    return await _db.getUpdatedRows();
  }

  @override
  Future<QueryResult> runSelect(String statement, List args) async {
    final stmt = await _db.prepare(statement);
    final result = await stmt.select(args);
    await stmt.close();

    return Future.value(QueryResult(result.columnNames, result.rows));
  }
}

class _VmVersionDelegate extends DynamicVersionDelegate {
  final BaseDatabase database;

  _VmVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion => Future.value(database.userVersion());

  @override
  Future<void> setSchemaVersion(int version) async {
    await database.setUserVersion(version);
    return Future.value();
  }
}
