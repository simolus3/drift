import 'dart:collection';

import 'package:collection/collection.dart';

/// Information about where we expect a high-level drift column to appear in the
/// low-level result map returned by database implementation.
///
/// Drift generates a unique [name] used as an alias in the query (e.g. `SELECT
/// &lt;expr&gt; AS c1`) and also remembers its position ([index]).
typedef ColumnPosition = ({String name, int index});

final class QueryResult {
  final int? affectedRows;
  // todo: Last insert rowid? Is sqlite specific
  final RawResultSet? resultSet;

  QueryResult({required this.affectedRows, required this.resultSet});
}

abstract base class RawResultSet
    with ListMixin<RawRow>, NonGrowableListMixin<RawRow> {
  RawResultSet();

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
