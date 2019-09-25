part of '../analysis.dart';

/// A column that appears in a [ResultSet]. Has a type and a name.
abstract class Column with Referencable implements Typeable {
  /// The name of this column in the result set.
  String get name;

  const Column();
}

/// A column that is part of a table.
class TableColumn extends Column {
  @override
  final String name;

  /// The type of this column, which is available before any resolution happens
  /// (we know if from the table).
  final ResolvedType type;

  /// The column constraints set on this column.
  ///
  /// See also:
  /// - https://www.sqlite.org/syntax/column-constraint.html
  final List<ColumnConstraint> constraints;

  /// The table this column belongs to.
  Table table;

  TableColumn(this.name, this.type, {this.constraints = const []});
}

/// A column that is created by an expression. For instance, in the select
/// statement "SELECT 1 + 3", there is a column called "1 + 3" of type int.
class ExpressionColumn extends Column {
  @override
  final String name;

  /// The expression returned by this column.
  final Expression expression;

  ExpressionColumn({@required this.name, this.expression});
}

/// The result column of a [CompoundSelectStatement].
class CompoundSelectColumn extends Column {
  /// The column in [CompoundSelectStatement.base] each of the
  /// [CompoundSelectStatement.additional] that contributed to this column.
  final List<Column> columns;

  CompoundSelectColumn(this.columns);

  @override
  String get name => columns.first.name;
}
