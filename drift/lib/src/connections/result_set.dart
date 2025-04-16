import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Information about where we expect a high-level drift column to appear in the
/// low-level result map returned by database implementation.
///
/// Drift generates a unique [name] used as an alias in the query (e.g. `SELECT
/// &lt;expr&gt; AS c1`) and also remembers its position ([index]).
typedef ColumnPosition = ({String name, int index});

@immutable
final class QueryResult {
  final int? affectedRows;
  final int? lastInsertRowId;

  final RawResultSet? resultSet;

  const QueryResult({
    this.affectedRows,
    this.lastInsertRowId,
    required this.resultSet,
  });
}

@immutable
abstract base class RawResultSet
    with ListMixin<RawRow>, NonGrowableListMixin<RawRow> {
  RawResultSet();

  factory RawResultSet.generate(
    int length,
    RawRow Function(int index, RawResultSet resultSet) generate,
  ) = _GeneratedResultSet;

  @override
  void operator []=(int index, RawRow value) {
    throw UnsupportedError("Can't change rows from a result set");
  }
}

@immutable
abstract base class RawRow {
  final RawResultSet resultSet;

  const RawRow({required this.resultSet});

  const factory RawRow.by({
    required RawResultSet resultSet,
    required Object? Function(ColumnPosition) byPosition,
    required Object? Function(String) byName,
  }) = _CallbackRow;

  factory RawRow.byMap({
    required RawResultSet resultSet,
    required Map<String, Object?> values,
  }) {
    return RawRow.by(
      resultSet: resultSet,
      byPosition: (pos) => values[pos.name],
      byName: (name) => values[name],
    );
  }

  Object? rawValue(ColumnPosition position);

  Object? byName(String name);
}

@immutable
final class _GeneratedResultSet extends RawResultSet {
  @override
  final int length;
  final RawRow Function(int, RawResultSet) _generate;

  _GeneratedResultSet(this.length, this._generate);

  @override
  RawRow operator [](int index) => _generate(index, this);
}

@immutable
final class _CallbackRow extends RawRow {
  final Object? Function(ColumnPosition) _byPosition;
  final Object? Function(String) _byName;

  const _CallbackRow(
      {required super.resultSet,
      required Object? Function(ColumnPosition) byPosition,
      required Object? Function(String) byName})
      : _byPosition = byPosition,
        _byName = byName;

  @override
  Object? byName(String name) {
    return _byName(name);
  }

  @override
  Object? rawValue(ColumnPosition position) {
    return _byPosition(position);
  }
}
