import 'package:meta/meta.dart';

import '../../database/data_class.dart';
import '../clauses/where.dart';
import '../expressions/boolean.dart';
import '../expressions/expression.dart';
import '../expressions/variables.dart';
import '../schema/result_set.dart';
import '../schema/table.dart';

/// Container for SQL statements that operate on a single primary SQL table.
@internal
abstract mixin class SingleTableStatementMixin<
  Row extends Object,
  RS extends ResultSet<Row, RS>,
  Self extends SingleTableStatementMixin<Row, RS, Self>
> {
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

/// Extension for statements on a table.
///
/// This adds the [whereSamePrimaryKey] method as an extension. The query could
/// run on a view, for which [whereSamePrimaryKey] is not defined.
extension QueryTableExtensions<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>,
  Self extends SingleTableStatementMixin<Row, RS, Self>
>
    on SingleTableStatementMixin<Row, RS, Self> {
  /// Applies a [where] statement so that the row with the same primary key as
  /// [d] will be matched.
  ///
  /// Note that, as far as primary key equality is concerned, `NULL` values are
  /// considered distinct from all values (including other `NULL`s).
  /// This matches sqlite3's behavior of not counting duplicate `NULL`s as a
  /// uniqueness constraint violation for primary keys, but makes it impossible
  /// to find other rows with [whereSamePrimaryKey] if nullable primary keys are
  /// used.
  Self whereSamePrimaryKey(Insertable<Row> d) {
    final source = resultSet as GeneratedTable;
    final primaryKey = source.primaryKey;

    assert(
      primaryKey?.isNotEmpty == true,
      'When using Query.whereSamePrimaryKey, which is also called from '
      'DeleteStatement.delete and UpdateStatement.replace, the affected table'
      'must have a primary key. You can either specify a primary implicitly '
      'by making an integer() column autoIncrement(), or by explictly '
      'overriding the primaryKey getter in your table class. You\'ll also '
      'have to re-run the code generation step.\n'
      'Alternatively, if you\'re using DeleteStatement.delete or '
      'UpdateStatement.replace, consider using DeleteStatement.go or '
      'UpdateStatement.write respectively. In that case, you need to use a '
      'custom where statement.',
    );

    final primaryKeyColumns = Map.fromEntries(
      primaryKey!.map((column) {
        return MapEntry(column.name, column);
      }),
    );

    final updatedFields = d.toColumns(false);
    // Construct a map of [GeneratedColumn] to [Expression] where each column is
    // a primary key and the associated value was extracted from d.
    final primaryKeyValues =
        Map.fromEntries(
          updatedFields.entries.where(
            (entry) => primaryKeyColumns.containsKey(entry.key),
          ),
        ).map((columnName, value) {
          return MapEntry(primaryKeyColumns[columnName]!, value);
        });

    assert(
      primaryKeyValues.values.every(
        (value) => value is! Variable || value.value != null,
      ),
      'Tried to find a row with a matching primary key that has a null value, '
      'which is not supported. In sqlite3, `NULL` values in a primary key are '
      'considered distinct from all other values (including other `NULL`s), so '
      "drift can't find a matching row for this query. \n"
      'For details, see https://github.com/simolus3/drift/issues/1956#issuecomment-1200502026',
    );

    final predicate = Expression.and([
      for (final entry in primaryKeyValues.entries)
        entry.key.equalsExp(entry.value),
    ]);

    return where((_) => predicate);
  }
}
