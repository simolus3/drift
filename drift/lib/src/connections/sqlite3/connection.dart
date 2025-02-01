import 'package:drift/core.dart';
import 'package:sqlite3/common.dart' as sqlite;

import '../../core/connection.dart';

final class SqliteConnection implements DriftConnection {
  final sqlite.CommonDatabase database;

  SqliteConnection(this.database);

  @override
  Future<RawResultSet> execute(CompiledStatement statement) async {
    final result = database.select(
        statement.buffer.toString(), statement.sqlVariables.toList());

    return _SqliteResultSet(
        resultSet: result, affectedRows: database.updatedRows);
  }
}

final class _SqliteResultSet extends RawResultSet {
  final sqlite.ResultSet resultSet;

  _SqliteResultSet({required this.resultSet, required super.affectedRows});

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
