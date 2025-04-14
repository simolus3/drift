import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart' as sqlite;

import '../../dialect/sqlite/dialect.dart';
import '../connection.dart';
import '../result_set.dart';
import 'native_functions.dart';

final class SqliteConnection implements DriftSession, DriftRootSession {
  final sqlite.CommonDatabase database;
  final SqliteDialect dialect;

  final Completer<void> _closedCompleter = Completer();

  SqliteConnection(this.dialect, this.database) {
    database.useNativeFunctions();
  }

  static DriftDatabaseImplementation synchronous(
      {required sqlite.CommonDatabase Function() open}) {
    final dialect = SqliteDialect();

    return DriftDatabaseImplementation(
      dialect: dialect,
      openConnection: () async => SqliteConnection(dialect, open()),
    );
  }

  @override
  Future<QueryResult> execute(StatementInfo statement) async {
    final sql = statement.sql;
    final variables = statement.sqlVariables(dialect).toList();
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
  Future<List<QueryResult>> executeBatch(List<StatementBatch> batch) async {
    final results = <QueryResult>[];
    for (final stmt in batch) {
      for (final instantiation in stmt.statements) {
        results.add(await execute(instantiation));
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
