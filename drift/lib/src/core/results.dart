import 'dart:collection';

import 'package:collection/collection.dart';

import 'dialect.dart';
import 'expressions/expression.dart';
import 'schema/result_set.dart';
import 'types.dart';

/// Information about where we expect a high-level drift column to appear in the
/// low-level result map returned by database implementation.
///
/// Drift generates a unique [name] used as an alias in the query (e.g. `SELECT
/// &lt;expr&gt; AS c1`) and also remembers its position ([index]).
typedef ColumnPosition = ({String name, int index});

final class ResultSetStructure {
  /// For [Expression] instances added to a query, the position of the column
  /// added for that expression.
  final Map<Expression, ColumnPosition> expressions = {};

  /// For each [ResultSet] that has been added to a query in its entirety, the
  /// a list of [ColumnPosition]s for each column in the result set.
  final Map<ResultSet, List<ColumnPosition>> tables = {};
}

abstract base class RawResultSet
    with ListMixin<RawRow>, NonGrowableListMixin<RawRow> {
  final int? affectedRows;
  // todo: Last insert rowid? Is sqlite specific

  RawResultSet({required this.affectedRows});

  @override
  void operator []=(int index, RawRow value) {
    throw UnsupportedError("Can't change rows from a result set");
  }
}

abstract base class RawRow {
  final RawResultSet resultSet;

  RawRow({required this.resultSet});

  Object? rawValue(ColumnPosition position);
}

final class DriftResultSet
    with ListMixin<DriftRow>, NonGrowableListMixin<DriftRow> {
  final ResultSetStructure structure;
  final RawResultSet resultSet;
  final DriftDialect dialect;

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

  Row? readTableOrNull<Row extends Object, RS extends ResultSet<Row, RS>>(
      RS resultSet) {
    return resultSet.mapToDart(this);
  }

  Row readTable<Row extends Object, RS extends ResultSet<Row, RS>>(
      RS resultSet) {
    return readTableOrNull(resultSet)!;
  }
}
