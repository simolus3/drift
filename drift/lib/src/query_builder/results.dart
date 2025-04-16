import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import '../connections/result_set.dart';
import '../runtime/type_converter.dart';
import 'dialect.dart';
import 'expressions/expression.dart';
import 'schema/column.dart';
import 'schema/result_set.dart';
import 'types.dart';

@immutable
final class ResultSetStructure {
  /// For [Expression] instances added to a query, the position of the column
  /// added for that expression.
  final IMap<Expression, ColumnPosition> expressions;

  /// For each [ResultSet] that has been added to a query in its entirety, the
  /// a list of [ColumnPosition]s for each column in the result set.
  final IMap<ResultSet, IList<ColumnPosition>> tables;

  const ResultSetStructure(
      {this.expressions = const IMap.empty(),
      this.tables = const IMap.empty()});

  ResultSetStructure copyWith({
    IMap<Expression, ColumnPosition>? expressions,
    IMap<ResultSet, IList<ColumnPosition>>? tables,
  }) {
    return ResultSetStructure(
      expressions: expressions ?? this.expressions,
      tables: tables ?? this.tables,
    );
  }

  ResultSetStructure withSelectStarFromSingleTable(ResultSet resultSet) {
    final tables = this.tables.unlock;
    final expressions = this.expressions.unlock;
    final positions = <ColumnPosition>[];
    for (final (i, column) in resultSet.columns.indexed) {
      final position = (name: column.name, index: i);
      expressions[column] = position;
      positions.add(position);
    }
    tables[resultSet] = IList(positions);

    return ResultSetStructure(
      expressions: expressions.lock,
      tables: tables.lock,
    );
  }

  /// Transforms this [ResultSetStructure] into a new one, mapping values in
  /// [expressions] to the given [outerPositions].
  ///
  /// This is mainly used internally, e.g. used to obtain the result of
  /// subqueries.
  ResultSetStructure shift(IList<ColumnPosition> outerPositions) {
    assert(outerPositions.length == expressions.length);
    ColumnPosition apply(ColumnPosition original) {
      return outerPositions[original.index];
    }

    return ResultSetStructure(
      expressions: expressions.map((e, pos) => MapEntry(e, apply(pos))),
      tables: tables.map((resultSet, positions) =>
          MapEntry(resultSet, positions.map(apply).toIList())),
    );
  }
}

@immutable
final class DriftResultSet
    with ListMixin<DriftRow>, NonGrowableListMixin<DriftRow> {
  final ResultSetStructure structure;
  final RawResultSet resultSet;
  final DriftDialect dialect;

  final Map<ResultSet, Object? Function(DriftRow)> _createdMappers = {};

  DriftResultSet(this.structure, this.resultSet, this.dialect);

  ColumnPosition _expressionPosition(Expression<Object> expression) {
    return switch (structure.expressions[expression]) {
      null => throw ArgumentError.value(expression, 'expression',
          'Has not been added as a column to the result set.'),
      final position => position,
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

    return (row) => row.readWithType(position, resolvedType);
  }

  Object? Function(DriftRow) _mapperFor(ResultSet resultSet) {
    return _createdMappers.putIfAbsent(
        resultSet, () => resultSet.createMapperToDart(structure));
  }
}

final class DriftRow {
  final DriftResultSet resultSet;
  final RawRow raw;

  DriftRow(this.resultSet, this.raw);

  T? readWithType<T extends Object>(ColumnPosition position, SqlType<T> type) {
    return switch (raw.rawValue(position)) {
      null => null,
      final value => type.dartValue(resultSet.dialect, value),
    };
  }

  T? read<T extends Object>(Expression<T> expr) {
    return readWithType(
      resultSet._expressionPosition(expr),
      expr.resolveType(resultSet.dialect),
    );
  }

  /// Reads a column that has a type converter applied to it from the row.
  ///
  /// This calls [read] internally, which reads the column but without applying
  /// a type converter.
  D? readWithConverter<D, S extends Object>(
      SchemaColumnWithTypeConverter<D, S> column) {
    return NullAwareTypeConverter.wrapFromSql(
        column.converter, read<S>(column));
  }

  Row? readTableOrNull<Row extends Object, RS extends ResultSet<Row, RS>>(
      RS resultSet) {
    return this.resultSet._mapperFor(resultSet)(this) as Row?;
  }

  Row readTable<Row extends Object, RS extends ResultSet<Row, RS>>(
      RS resultSet) {
    return readTableOrNull(resultSet)!;
  }
}
