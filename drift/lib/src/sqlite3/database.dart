@internal
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart';

import '../../backends.dart';
import 'native_functions.dart';

/// Common database implementation based on the `sqlite3` database.
///
/// Depending on the actual platform (reflected by [DB]), the database is either
/// a native database accessed through `dart:ffi` or a WASM database accessed
/// through `package:js`.
abstract class Sqlite3Delegate<DB extends CommonDatabase>
    extends DatabaseDelegate {
  late DB _db;

  bool _hasCreatedDatabase = false;
  bool _isOpen = false;

  final void Function(DB)? _setup;
  final bool _closeUnderlyingWhenClosed;

  /// A delegate that will call [openDatabase] to open the database.
  Sqlite3Delegate(this._setup) : _closeUnderlyingWhenClosed = true;

  /// A delegate using an underlying sqlite3 database object that has already
  /// been opened.
  Sqlite3Delegate.opened(this._db, this._setup, this._closeUnderlyingWhenClosed)
      : _hasCreatedDatabase = true {
    _initializeDatabase();
  }

  /// This method is overridden by the platform-specific implementation to open
  /// the right sqlite3 database instance.
  DB openDatabase();

  /// This method may optionally be overridden by the platform-specific
  /// implementation to get notified before a database would be closed.
  void beforeClose(DB database) {}

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  late DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen => Future.value(_isOpen);

  /// Flush pending writes to the file system on platforms where that is
  /// necessary.
  ///
  /// At the moment, we only support this for the WASM backend.
  FutureOr<void> flush() => null;

  @override
  Future<void> open(QueryExecutorUser db) async {
    if (!_hasCreatedDatabase) {
      _createDatabase();
      _initializeDatabase();
    }

    _isOpen = true;
    return Future.value();
  }

  void _createDatabase() {
    assert(!_hasCreatedDatabase);
    _hasCreatedDatabase = true;

    _db = openDatabase();
  }

  void _initializeDatabase() {
    _db.useNativeFunctions();
    _setup?.call(_db);
    versionDelegate = _VmVersionDelegate(_db);
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final prepared = [
      for (final stmt in statements.statements)
        _db.prepare(stmt, checkNoTail: true),
    ];

    for (final application in statements.arguments) {
      final stmt = prepared[application.statementIndex];

      stmt.execute(application.arguments);
    }

    for (final stmt in prepared) {
      stmt.dispose();
    }

    if (!isInTransaction) {
      await flush();
    }

    return Future.value();
  }

  Future _runWithArgs(String statement, List<Object?> args) async {
    if (args.isEmpty) {
      _db.execute(statement);
    } else {
      final stmt = _db.prepare(statement, checkNoTail: true);
      stmt.execute(args);
      stmt.dispose();
    }

    if (!isInTransaction) {
      await flush();
    }
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
    return _db.lastInsertRowId;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
    return _db.getUpdatedRows();
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final stmt = _db.prepare(statement, checkNoTail: true);
    final result = stmt.select(args);
    stmt.dispose();

    return Future.value(QueryResult.fromRows(result.toList()));
  }

  @override
  Future<void> close() async {
    if (_closeUnderlyingWhenClosed) {
      beforeClose(_db);
      _db.dispose();

      await flush();
    }
  }
}

class _VmVersionDelegate extends DynamicVersionDelegate {
  final CommonDatabase database;

  _VmVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion => Future.value(database.userVersion);

  @override
  Future<void> setSchemaVersion(int version) {
    database.userVersion = version;
    return Future.value();
  }
}
