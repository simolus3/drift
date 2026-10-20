import 'dart:collection';

import 'package:collection/collection.dart';

/// A result from an select statement.
class QueryResult {
  /// Names of the columns returned by the select statement.
  final List<String> columnNames;

  /// The data returned by the select statement. Each list represents a row,
  /// which has the data in the same order as [columnNames].
  final List<List<Object?>> rows;

  final Map<String, int> _columnIndexes;

  /// Constructs a [QueryResult] by specifying the order of column names in
  /// [columnNames] and the associated data in [rows].
  QueryResult(this.columnNames, this.rows)
    : _columnIndexes = {
        for (var column in columnNames) column: columnNames.lastIndexOf(column),
      };

  /// Converts the [rows] into [columnNames] and raw data [QueryResult.rows].
  /// We assume that each map in [rows] has the same keys.
  factory QueryResult.fromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return QueryResult(const [], const []);
    }

    final keys = rows.first.keys.toList();
    final mappedRows = [
      for (var row in rows) [for (var key in keys) row[key]],
    ];

    return QueryResult(keys, mappedRows);
  }

  /// Returns a "list of maps" representation of this result set. Each map has
  /// the same keys - the [columnNames]. The values are the actual values in
  /// the row. The maps are read-only views on [rows].
  Iterable<Map<String, dynamic>> get asMap {
    return rows.map((row) => _QueryResultRow(_columnIndexes, row));
  }
}

/// A read-only map view of one row in a [QueryResult].
///
/// All rows share the column index map of their [QueryResult], so creating a
/// row does not create a new hash map.
final class _QueryResultRow extends MapBase<String, Object?>
    with UnmodifiableMapMixin<String, Object?> {
  final Map<String, int> _columnIndexes;
  final List<Object?> _row;

  _QueryResultRow(this._columnIndexes, this._row);

  @override
  Object? operator [](Object? key) {
    final index = _columnIndexes[key];
    return index == null ? null : _row[index];
  }

  @override
  bool containsKey(Object? key) => _columnIndexes.containsKey(key);

  @override
  Iterable<String> get keys => _columnIndexes.keys;

  @override
  int get length => _columnIndexes.length;
}
