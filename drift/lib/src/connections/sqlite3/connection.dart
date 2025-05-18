import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart' as sqlite;

import '../../dialect/sqlite/dialect.dart';
import '../connection.dart';
import '../result_set.dart';
import 'native_functions.dart';

/// A [DriftSession] implemented by synchronously running queries against a
/// [sqlite.CommonDatabase].
///
/// This is not a recommended implementation to use directly. Instead, use
/// packages like `drift_flutter` or utilities provided in this package to setup
/// a background pool of isolate to run queries.
final class SqliteConnection implements DriftSession, DriftRootSession {
  /// The database used for the connection.
  final sqlite.CommonDatabase database;

  /// Whether the [database] should be closed when [close] is called on this
  /// instance.
  ///
  /// This defaults to `true`, but can be disabled to virtually open multiple
  /// connections to the same database.
  final bool closeUnderlyingWhenClosed;

  /// Whether this connection implementation will cache prepared statements to
  /// re-use them when used frequently (as opposed to re-compiling them every
  /// time they're executed).
  final bool cachePreparedStatements;

  final PreparedStatementsCache _preparedStmtsCache = PreparedStatementsCache();

  final Completer<void> _closedCompleter = Completer();

  /// Wrap a [database] as a [DriftSession].
  SqliteConnection(
    this.database, {
    this.cachePreparedStatements = true,
    this.closeUnderlyingWhenClosed = true,
  }) {
    database.useNativeFunctions();
  }

  @override
  Object? get tag => null;

  @override
  DriftRootSession? get root => this;

  @override
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => null;

  @override
  DriftSessionWithInternalLocks? get locks => null;

  @override
  Future<QueryResult> execute(StatementInfo statement) async {
    final sql = statement.sql;
    if (statement.variables.isEmpty && !statement.needsResultSet) {
      // Do this because it allows running multiple statements at once
      database.execute(sql);

      return QueryResult(
        affectedRows: database.updatedRows,
        resultSet: null,
        lastInsertRowId: database.lastInsertRowId,
      );
    }

    final (stmt, isCached) = _getPreparedStatement(sql);

    try {
      return _executeWithStatement(stmt, statement);
    } finally {
      _returnStatement(stmt, isCached);
    }
  }

  QueryResult _executeWithStatement(
      sqlite.CommonPreparedStatement stmt, StatementInfo info) {
    final variables = info.variables.map((e) => e.rawValue).toList();
    RawResultSet? resultSet;

    if (info.needsResultSet) {
      resultSet = SqliteResultSet(resultSet: stmt.select(variables));
    } else {
      stmt.execute(variables);
    }

    return QueryResult(
      affectedRows: database.updatedRows,
      resultSet: resultSet,
      lastInsertRowId: database.lastInsertRowId,
    );
  }

  @override
  Future<List<QueryResult>> executeBatch(StatementBatch batch) async {
    final results = <QueryResult>[];
    final prepared = <(sqlite.CommonPreparedStatement, bool)>[];

    try {
      for (final sql in batch.sql) {
        prepared.add(_getPreparedStatement(sql));
      }

      for (final stmt in batch.statements) {
        results
            .add(_executeWithStatement(prepared[stmt.sqlIndex].$1, stmt.info));
      }
    } finally {
      for (final (stmt, isCached) in prepared) {
        _returnStatement(stmt, isCached);
      }
    }

    return results;
  }

  @override
  bool get isClosed => _closedCompleter.isCompleted;

  @override
  Future<void> get closed => _closedCompleter.future;

  @override
  Future<void> close() async {
    if (!_closedCompleter.isCompleted) {
      _preparedStmtsCache.disposeAll();

      if (closeUnderlyingWhenClosed) {
        database.dispose();
      }
      _closedCompleter.complete();
    }

    return closed;
  }

  @override
  Future<int> get schemaVersion async => database.userVersion;

  @override
  Future<void> writeSchemaVersion(int version) async {
    database.userVersion = version;
  }

  /// Returns a prepared statement for [sql] and reports whether this statement
  /// was cached.
  (sqlite.CommonPreparedStatement, bool) _getPreparedStatement(String sql) {
    if (cachePreparedStatements) {
      final cachedStmt = _preparedStmtsCache.use(sql);
      if (cachedStmt != null) {
        return (cachedStmt, true);
      }

      final stmt = database.prepare(sql, checkNoTail: true);
      if (!stmt.isExplain) {
        _preparedStmtsCache.addNew(sql, stmt);
      }

      return (stmt, !stmt.isExplain);
    } else {
      final stmt = database.prepare(sql, checkNoTail: true);
      return (stmt, false);
    }
  }

  void _returnStatement(sqlite.CommonPreparedStatement stmt, bool cached) {
    // When using a statement cache, prepared statements are disposed as they
    // get evicted from the cache, so we don't need to do anything.
    if (!cached) {
      stmt.dispose();
    }
  }

  /// Returns a [DriftConnection] backed by a SQLite
  /// [sqlite.CommonDatabase] obtained by calling [open].
  ///
  /// Closing this [SqliteConnection] will close the database.
  static DriftConnection synchronous(
      {required sqlite.CommonDatabase Function() open,
      SqliteDialect dialect = const SqliteDialect()}) {
    return DriftConnection(
      dialect: dialect,
      openConnection: () async => SqliteConnection(open()),
    );
  }
}

@internal
final class SqliteResultSet extends RawResultSet {
  final sqlite.ResultSet resultSet;

  SqliteResultSet({required this.resultSet});

  @override
  RawRow operator [](int index) {
    return _SqliteRow(row: resultSet[index], resultSet: this);
  }

  @override
  int get length => resultSet.length;
}

final class _SqliteRow extends RawRow {
  final sqlite.Row row;

  _SqliteRow({required this.row, required super.resultSet});

  @override
  Object? rawValue(ColumnPosition position) {
    return row.columnAt(position.index);
  }

  @override
  Object? byName(String name) {
    return row[name];
  }
}

/// A cache of prepared statements to avoid having to parse SQL statements
/// multiple time when they're used frequently.
@internal
final class PreparedStatementsCache {
  /// The default amount of prepared statements to keep cached.
  ///
  /// This value is used in tests to verify that evicted statements get disposed.
  @visibleForTesting
  static const defaultSize = 64;

  /// The maximum amount of cached statements.
  final int maxSize;

  // The linked map returns entries in the order in which they have been
  // inserted (with the first insertion being reported first).
  // So, we treat it as a LRU cache with `entries.last` being the MRU and
  // `entries.first` being the LRU element.
  final LinkedHashMap<String, sqlite.CommonPreparedStatement>
      _cachedStatements = LinkedHashMap();

  /// Create a cache of prepared statements with a capacity of [maxSize].
  PreparedStatementsCache({this.maxSize = defaultSize});

  /// Attempts to look up the cached [sql] statement, if it exists.
  ///
  /// If the statement exists, it is marked as most recently used as well.
  sqlite.CommonPreparedStatement? use(String sql) {
    // Remove and add the statement if it was found to move it to the end,
    // which marks it as the MRU element.
    final foundStatement = _cachedStatements.remove(sql);

    if (foundStatement != null) {
      _cachedStatements[sql] = foundStatement;
    }

    return foundStatement;
  }

  /// Caches a statement that has not been cached yet for subsequent uses.
  void addNew(String sql, sqlite.CommonPreparedStatement statement) {
    assert(!_cachedStatements.containsKey(sql));

    if (_cachedStatements.length == maxSize) {
      final lru = _cachedStatements.remove(_cachedStatements.keys.first)!;
      lru.dispose();
    }

    _cachedStatements[sql] = statement;
  }

  /// Removes all cached statements.
  void disposeAll() {
    for (final statement in _cachedStatements.values) {
      statement.dispose();
    }

    _cachedStatements.clear();
  }

  /// Forgets cached statements without explicitly disposing them.
  void clear() {
    _cachedStatements.clear();
  }
}
