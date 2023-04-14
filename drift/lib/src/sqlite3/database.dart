@internal
import 'dart:async';
import 'dart:developer';

import 'package:meta/dart2js.dart' as dart2js;
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
  DB? _database;

  /// The underlying database instance from the `sqlite3` package.
  DB get database => _database!;

  bool _hasInitializedDatabase = false;
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
      this._database, this._setup, this.closeUnderlyingWhenClosed) {
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
    if (!_hasInitializedDatabase) {
      assert(_database == null);
      _database = openDatabase();

      try {
        _initializeDatabase();
      } catch (e) {
        // If the initialization fails, we effectively don't have a usable
        // database, so reset
        _database?.dispose();
        _database = null;

        rethrow;
      }
    }

    _isOpen = true;
    return Future.value();
  }

  void _initializeDatabase() {
    assert(!_hasInitializedDatabase);

    database.useNativeFunctions();
    _setup?.call(database);
    versionDelegate = _SqliteVersionDelegate(database);
    _hasInitializedDatabase = true;
  }

  /// Synchronously prepares and runs [statements] collected from a batch.
  @protected
  void runBatchSync(BatchedStatements statements) {
    Timeline.startSync('drift/runBatchSync');
    final prepared = <CommonPreparedStatement>[];

    try {
      for (final stmt in statements.statements) {
        prepared.add(_prepare(stmt));
      }

      Timeline.timeSync('drift/runBatchSync/execute', () {
        for (final application in statements.arguments) {
          final stmt = prepared[application.statementIndex];

          stmt.execute(application.arguments);
        }
      });
    } finally {
      for (final stmt in prepared) {
        stmt.dispose();
      }
      Timeline.finishSync();
    }
  }

  /// Synchronously prepares and runs a single [statement], replacing variables
  /// with the given [args].
  @protected
  void runWithArgsSync(String statement, List<Object?> args) {
    Timeline.timeSync('drift/runWithArgsSync', () {
      if (args.isEmpty) {
        database.execute(statement);
      } else {
        final stmt = _prepare(statement);
        try {
          stmt.execute(args);
        } finally {
          stmt.dispose();
        }
      }
    }, arguments: {'sql': statement});
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    Timeline.startSync('drift/runSelect');
    final stmt = _prepare(statement);
    try {
      final result = stmt.select(args);
      return QueryResult.fromRows(result.toList());
    } finally {
      Timeline.finishSync();
      stmt.dispose();
    }
  }

  @pragma('vm:prefer-inline')
  @dart2js.tryInline
  CommonPreparedStatement _prepare(String sql) {
    Timeline.startSync('drift/prepare', arguments: {'sql': sql});
    try {
      return database.prepare(sql, checkNoTail: true);
    } finally {
      Timeline.finishSync();
    }
  }
}

class _SqliteVersionDelegate extends DynamicVersionDelegate {
  final CommonDatabase database;

  _SqliteVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion => Future.value(database.userVersion);

  @override
  Future<void> setSchemaVersion(int version) {
    database.userVersion = version;
    return Future.value();
  }
}
