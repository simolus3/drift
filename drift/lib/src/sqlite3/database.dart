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
  /// The underlying database instance from the `sqlite3` package.
  late DB database;

  bool _hasCreatedDatabase = false;
  bool _isOpen = false;

  final void Function(DB)? _setup;

  /// Whether the [database] should be closed when [close] is called on this
  /// instance.
  ///
  /// This defaults to `true`, but can be disabled to virtually open multiple
  /// connections to the same database.
  final bool closeUnderlyingWhenClosed;

  /// A delegate that will call [openDatabase] to open the database.
  Sqlite3Delegate(this._setup) : closeUnderlyingWhenClosed = true;

  /// A delegate using an underlying sqlite3 database object that has already
  /// been opened.
  Sqlite3Delegate.opened(
      this.database, this._setup, this.closeUnderlyingWhenClosed)
      : _hasCreatedDatabase = true {
    _initializeDatabase();
  }

  /// This method is overridden by the platform-specific implementation to open
  /// the right sqlite3 database instance.
  DB openDatabase();

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  late DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen => Future.value(_isOpen);

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

    database = openDatabase();
  }

  void _initializeDatabase() {
    database.useNativeFunctions();
    _setup?.call(database);
    versionDelegate = _VmVersionDelegate(database);
  }

  /// Synchronously prepares and runs [statements] collected from a batch.
  @protected
  void runBatchSync(BatchedStatements statements) {
    final prepared = <CommonPreparedStatement>[];

    try {
      for (final stmt in statements.statements) {
        prepared.add(database.prepare(stmt, checkNoTail: true));
      }

      for (final application in statements.arguments) {
        final stmt = prepared[application.statementIndex];

        stmt.execute(application.arguments);
      }
    } finally {
      for (final stmt in prepared) {
        stmt.dispose();
      }
    }
  }

  /// Synchronously prepares and runs a single [statement], replacing variables
  /// with the given [args].
  @protected
  void runWithArgsSync(String statement, List<Object?> args) {
    if (args.isEmpty) {
      database.execute(statement);
    } else {
      final stmt = database.prepare(statement, checkNoTail: true);
      try {
        stmt.execute(args);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final stmt = database.prepare(statement, checkNoTail: true);
    try {
      final result = stmt.select(args);
      return QueryResult.fromRows(result.toList());
    } finally {
      stmt.dispose();
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
