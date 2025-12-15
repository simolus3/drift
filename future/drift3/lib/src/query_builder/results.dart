import 'dart:collection';

import 'package:collection/collection.dart';

import '../connection/result_set.dart';
import 'dialect.dart';
import 'expressions/expression.dart';
import 'schema/column.dart';
import 'schema/result_set.dart';
import 'type_converter.dart';
import 'types.dart';

/// Information about where we expect a high-level drift column to appear in the
/// low-level result map returned by database implementation.
///
/// Drift generates a unique [name] used as an alias in the query (e.g. `SELECT
/// &lt;expr&gt; AS c1`) and also remembers its position ([index]).
final class ColumnPosition {
  /// The index of this column in the result set.
  final int index;

  String? _fixedResultName;

  /// If [name] has been called, the fixed alias to use for this column.
  String? get resultAlias => _fixedResultName;

  /// A stable name for this column.
  ///
  /// This is computed on-demand. When called, a new name is assigned to this
  /// column.
  String get name => _fixedResultName ??= 'c$index';

  /// Creates a column position from the [index].
  ColumnPosition(this.index);
}

final class ResultSetStructure {
  /// For [Expression] instances added to a query, the index of the column
  /// added for that expression.
  final Map<Expression, ColumnPosition> expressions;

  /// For each [ResultSet] that has been added to a query in its entirety, the
  /// a list of column indices for each column in the result set.
  final Map<ResultSet, List<ColumnPosition>> tables;

  ResultSetStructure({
    Map<Expression, ColumnPosition>? expressions,
    Map<ResultSet, List<ColumnPosition>>? tables,
  }) : expressions = expressions ?? {},
       tables = tables ?? {};

  /// Adds all columns from the given [ResultSet] in order.
  void addSelectStarFromSingleTable(ResultSet resultSet) {
    final positions = <ColumnPosition>[];
    for (final (i, column) in resultSet.columns.indexed) {
      final position = ColumnPosition(i);
      expressions[column] = position;
      positions.add(position);
    }

    tables[resultSet] = positions;
  }

  /// Transforms this [ResultSetStructure] into a new one, mapping values in
  /// [expressions] to the given [outerPositions].
  ///
  /// This is mainly used internally, e.g. used to obtain the result of
  /// subqueries.
  ResultSetStructure shift(List<ColumnPosition> outerPositions) {
    assert(outerPositions.length == expressions.length);
    ColumnPosition apply(ColumnPosition original) {
      return outerPositions[original.index];
    }

    return ResultSetStructure(
      expressions: expressions.map((e, pos) => MapEntry(e, apply(pos))),
      tables: tables.map(
        (resultSet, positions) =>
            MapEntry(resultSet, positions.map(apply).toList()),
      ),
    );
  }
}

final class DriftResultSet
    with ListMixin<DriftRow>, NonGrowableListMixin<DriftRow> {
  final ResultSetStructure structure;
  final RawResultSet resultSet;
  final DriftDialect dialect;

  Map<ResultSet, Object? Function(DriftRow)> _createdMappers = {};

  DriftResultSet(this.structure, this.resultSet, this.dialect);

  ColumnPosition _expressionPosition(Expression<Object> expression) {
    return switch (structure.expressions[expression]) {
      null => throw ArgumentError.value(
        expression,
        'expression',
        'Has not been added as a column to the result set.',
      ),
      final index => index,
    };
  }

  @override
  int get length => resultSet.length;

  @override
  void operator []=(int index, DriftRow value) {
    throw UnsupportedError("Can't change rows from a result set");
  }

  @override
  DriftRow operator [](int index) {
    return DriftRow(this, resultSet[index]);
  }

  T? Function(DriftRow) bindExpression<T extends Object>(Expression<T> expr) {
    final position = _expressionPosition(expr);
    final resolvedType = expr.resolveType(dialect);

    return (row) => row._readAtPositionWithType(position, resolvedType);
  }

  Object? Function(DriftRow) _mapperFor(ResultSet resultSet) {
    return _createdMappers.putIfAbsent(
      resultSet,
      () => resultSet.createMapperToDart(structure),
    );
  }
}

final class DriftRow {
  final DriftResultSet resultSet;
  final RawRow raw;

  DriftRow(this.resultSet, this.raw);

  T? _readAtPositionWithType<T extends Object>(
    ColumnPosition position,
    PhysicalSqlType<T> type,
  ) {
    return switch (raw[position.index]) {
      null => null,
      final value => type.dartValue(value),
    };
  }

  T? read<T extends Object>(Expression<T> expr) {
    return _readAtPositionWithType(
      resultSet._expressionPosition(expr),
      expr.resolveType(resultSet.dialect),
    );
  }

  /// Reads a column that has a type converter applied to it from the row.
  ///
  /// This calls [read] internally, which reads the column but without applying
  /// a type converter.
  D? readWithConverter<D, S extends Object>(
    SchemaColumnWithTypeConverter<D, S> column,
  ) {
    return NullAwareTypeConverter.wrapFromSql(
      column.converter,
      read<S>(column),
    );
  }

  Row? readTableOrNull<Row extends Object, RS extends ResultSet<Row, RS>>(
    RS resultSet,
  ) {
    return this.resultSet._mapperFor(resultSet)(this) as Row?;
  }

  Row readTable<Row extends Object, RS extends ResultSet<Row, RS>>(
    RS resultSet,
  ) {
    final parsed = readTableOrNull<Row, RS>(resultSet);
    if (parsed == null) {
      throw ArgumentError(
        'Invalid table passed to readTable: ${resultSet.aliasOrName}. This row '
        'does not contain values for that table. \n'
        'Please use readTableOrNull for outer joins.',
      );
    }

    return parsed;
  }
}
