import 'package:meta/meta.dart';

import '../clauses/where.dart';
import '../expressions/boolean.dart';
import '../expressions/expression.dart';
import '../schema/result_set.dart';

/// Container for SQL statements that operate on a single primary SQL table.
abstract mixin class SingleTableStatementMixin<
    Row extends Object,
    RS extends ResultSet<Row, RS>,
    Self extends SingleTableStatementMixin<Row, RS, Self>> {
  /// The [ResultSet] that this statement is primarily operating on.
  ResultSet<Row, RS> get resultSet;

  /// The [WhereClause] filtering rows for this statement.
  WhereClause? whereClause;

  /// Returns `this` as [Self].
  @internal
  Self asSelf();

  /// Makes this statement only include rows that match the [filter].
  ///
  /// For instance, if you have a table users with an id column, you could
  /// select a user with a specific id by using
  /// ```dart
  /// select(users).where((u) => u.id.equals(42)).watchSingle()
  /// ```
  ///
  /// Please note that this [where] call is different to [Iterable.where] and
  /// [Stream.where] in the sense that [filter] will NOT be called for each
  /// row. Instead, it will only be called once (with the underlying table as
  /// parameter). The result [Expression] will be written as a SQL string and
  /// sent to the underlying database engine. The filtering does not happen in
  /// Dart.
  /// If a where condition has already been set before, the resulting filter
  /// will be the conjunction of both calls.
  ///
  /// For more information, see:
  ///  - The docs on [expressions](https://drift.simonbinder.eu/docs/getting-started/expressions/),
  ///    which explains how to express most SQL expressions in Dart.
  ///
  /// If you want to remove duplicate rows from a query, use the `distinct`
  /// parameter on [DatabaseConnectionUser.select].
  Self where(Expression<bool> Function(RS tbl) filter) {
    final predicate = filter(resultSet.asSelfType());

    if (whereClause == null) {
      whereClause = WhereClause(predicate);
    } else {
      whereClause = WhereClause(whereClause!.condition & predicate);
    }

    return asSelf();
  }
}
