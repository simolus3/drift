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

/// The expected column structure of a result set.
///
/// This contains positions for [expressions] as well as the list of positions
/// for each table added to the result set in [tables].
///
/// This information is used when mapping values to Dart. A table would look
/// itself up in [tables] to obtain indices of its columns in each row. These
/// positions are then used when each row is mapped to Dart, avoiding the
/// duplicate map lookup.
final class ResultSetStructure {
  /// For [Expression] instances added to a query, the index of the column
  /// added for that expression.
  final Map<Expression, ColumnPosition> expressions;

  /// For each [ResultSet] that has been added to a query in its entirety, the
  /// a list of column indices for each column in the result set.
  final Map<ResultSet, List<ColumnPosition>> tables;

  /// @nodoc
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

/// A list of [DriftRow]s from which structured values can be read in a
/// type-safe way.
///
/// [DriftRow]s are used to represent the results of running `SELECT`
/// statements.
final class DriftResultSet
    with ListMixin<DriftRow>, NonGrowableListMixin<DriftRow> {
  /// The structure of this result set, describing which columns are available.
  final ResultSetStructure structure;

  /// The underlying [RawResultSet] from the database connection.
  final RawResultSet resultSet;

  /// The dialect, used to resolve SQL type implementations when reading values.
  final DriftDialect dialect;

  final Map<ResultSet, Object? Function(DriftRow)> _createdMappers = {};

  /// @nodoc
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

  /// Returns a function reading the given expression from a [DriftRow] of this
  /// result set.
  ///
  /// When reading expressions from many rows, calling [bindExpression] and then
  /// invoking the returned function for each row is faster than calling
  /// [DriftRow.read] on each row since types only have to be resolved once.
  T? Function(DriftRow) bindExpression<T extends Object>(Expression<T> expr) {
    final position = _expressionPosition(expr);
    final resolvedType = expr.resolveType(dialect);

    return (row) => row._readAtPositionWithType(position, resolvedType);
  }

  Object? Function(DriftRow) _mapperFor(ResultSet resultSet) {
    return _createdMappers.putIfAbsent(resultSet, () {
      return resultSet.createMapperToDart(structure);
    });
  }
}

/// A row in a [DriftResultSet].
final class DriftRow {
  /// The result set describing the column structure of this row.
  final DriftResultSet resultSet;

  /// The underlying [RawRow].
  final RawRow raw;

  /// @nodoc
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

  /// Reads the value of evaluating [Expression] from this row.
  ///
  /// The expression must have been added to the select statement (either
  /// through a result set or through [BaseSelectStatement.addColumn]).
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

  /// Reads a full [ResultSet] from this row.
  ///
  /// For result sets that might be absent from some rows (e.g. those added as
  /// outer joins), consider using [readTableOrNull] instead.
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

  /// Reads a full [ResultSet] from this row, or null if it doesn't have
  /// non-null values in this row.
  ///
  /// This does not allow reading result sets whose columns don't exist in this
  /// row at all (e.g. a result set not joined into a select statement).
  Row? readTableOrNull<Row extends Object, RS extends ResultSet<Row, RS>>(
    RS resultSet,
  ) {
    return this.resultSet._mapperFor(resultSet)(this) as Row?;
  }
}
