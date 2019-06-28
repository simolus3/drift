import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';

abstract class SqlQuery {
  final String name;

  SqlQuery(this.name);
}

class SqlSelectQuery extends SqlQuery {
  final List<SpecifiedTable> readsFrom;
  final InferredResultSet resultSet;

  SqlSelectQuery(String name, this.readsFrom, this.resultSet) : super(name);
}

class InferredResultSet {
  /// If the result columns of a SELECT statement exactly match one table, we
  /// can just use the data class generated for that table. Otherwise, we'd have
  /// to create another class.
  // todo implement this check
  final SpecifiedTable matchingTable;
  final List<ResultColumn> columns;

  InferredResultSet(this.matchingTable, this.columns);
}

class ResultColumn {
  final String name;
  final ColumnType type;
  final bool nullable;

  ResultColumn(this.name, this.type, this.nullable);
}
