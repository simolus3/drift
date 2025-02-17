import 'package:sqlite3/common.dart' as sqlite;

import '../../dialect/sqlite.dart';
import '../connection.dart';
import '../result_set.dart';

final class SqliteConnection implements DriftSession {
  final sqlite.CommonDatabase database;
  final SqliteDialect dialect;

  SqliteConnection(this.dialect, this.database);

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
      resultSet = _SqliteResultSet(resultSet: database.select(sql, variables));
    } else {
      database.execute(sql, variables);
    }

    return QueryResult(
      affectedRows: database.updatedRows,
      resultSet: resultSet,
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
  Future<void> close() async {
    database.dispose();
  }
}

final class _SqliteResultSet extends RawResultSet {
  final sqlite.ResultSet resultSet;

  _SqliteResultSet({required this.resultSet});

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
}
