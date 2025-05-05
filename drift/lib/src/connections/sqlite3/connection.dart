import 'dart:async';

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

  final Completer<void> _closedCompleter = Completer();

  /// Wrap a [database] as a [DriftSession].
  SqliteConnection(this.database) {
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
    final variables = statement.variables.map((e) => e.rawValue).toList();
    RawResultSet? resultSet;

    if (statement.needsResultSet) {
      resultSet = SqliteResultSet(resultSet: database.select(sql, variables));
    } else {
      database.execute(sql, variables);
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
    for (final stmt in batch.statements) {
      results.add(await execute(stmt.info));
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
      database.dispose();
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

  /// Returns a [DriftDatabaseImplementation] backed by a SQLite
  /// [sqlite.CommonDatabase] obtained by calling [open].
  ///
  /// Closing this [SqliteConnection] will close the database.
  static DriftDatabaseImplementation synchronous(
      {required sqlite.CommonDatabase Function() open,
      SqliteDialect dialect = const SqliteDialect()}) {
    return DriftDatabaseImplementation(
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
