@internal
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart';
import 'package:quiver/collection.dart';

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

  /// Whether prepared statements should be cached.
  final bool cachePreparedStatements;

  /// Whether the [database] should be closed when [close] is called on this
  /// instance.
  ///
  /// This defaults to `true`, but can be disabled to virtually open multiple
  /// connections to the same database.
  final bool closeUnderlyingWhenClosed;

  final _PreparedStatementsCache _preparedStmtsCache =
      _PreparedStatementsCache();

  /// A delegate that will call [openDatabase] to open the database.
  Sqlite3Delegate(
    this._setup, {
    required this.cachePreparedStatements,
  }) : closeUnderlyingWhenClosed = true;

  /// A delegate using an underlying sqlite3 database object that has already
  /// been opened.
  Sqlite3Delegate.opened(
    this._database,
    this._setup,
    this.closeUnderlyingWhenClosed, {
    required this.cachePreparedStatements,
  }) {
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

        disposePreparedStmtsCache();

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

  /// Disposes the prepared statements held in the cache.
  @protected
  void disposePreparedStmtsCache() {
    _preparedStmtsCache.dispose();
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
      final stmt = _getPreparedStatement(statement);
      stmt.execute(args);
    }
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final stmt = _getPreparedStatement(statement);
    final result = stmt.select(args);
    return QueryResult.fromRows(result.toList());
  }

  CommonPreparedStatement _getPreparedStatement(String statement) {
    if (cachePreparedStatements) {
      final cachedStmt = _preparedStmtsCache._getCachedStatement(statement);

      if (cachedStmt != null) {
        return cachedStmt;
      }

      final stmt = database.prepare(statement, checkNoTail: true);

      _preparedStmtsCache.add(statement, stmt);

      return stmt;
    } else {
      final stmt = database.prepare(statement, checkNoTail: true);
      return stmt;
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

class _PreparedStatementsCache {
  final LruMap<String, CommonPreparedStatement> _cache = LruMap(
      // Currently quiver LRU doesn't return the removed entries,
      // so we can't dispose them. Unlimited cache size until we find
      // a solution.
      // maximumSize: 64,
      );

  /// Returns the cached prepared statement for the given [sql], or `null` if there is none.
  CommonPreparedStatement? _getCachedStatement(String sql) {
    final stmt = _cache[sql];
    return stmt;
  }

  /// Adds the given [stmt] to the cache.
  void add(String sql, CommonPreparedStatement stmt) {
    _cache[sql] = stmt;
  }

  /// Removes the statement with the given [sql] from the cache.
  void remove(String sql) {
    final stmt = _cache.remove(sql);
    stmt?.dispose();
  }

  /// Disposes all cached statements.
  void dispose() {
    for (final stmt in _cache.values) {
      stmt.dispose();
    }
    _cache.clear();
  }
}
