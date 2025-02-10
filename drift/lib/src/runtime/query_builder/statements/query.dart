part of '../query_builder.dart';

/// Statement that operates with data that already exists (select, delete,
/// update).
abstract class Query<T extends HasResultSet, D> extends Component {
  /// The database this statement should be sent to.
  @protected
  DatabaseConnectionUser database;

  /// The (main) table or view that this query operates on.
  ResultSetImplementation<T, D> table;

  /// Used internally by drift. Users should use the appropriate methods on
  /// [DatabaseConnectionUser] instead.
  Query(this.database, this.table);

  /// The `WHERE` clause for this statement
  @protected
  Where? whereExpr;

  /// The `ORDER BY` clause for this statement
  @protected
  OrderBy? orderByExpr;

  /// The `LIMIT` clause for this statement.
  @protected
  Limit? limitExpr;

  /// Whether a `RETURNING *` clause should be added to this statement.
  @protected
  bool writeReturningClause = false;

  GroupBy? _groupBy;

  /// Subclasses must override this and write the part of the statement that
  /// comes before the where and limit expression..
  @visibleForOverriding
  void writeStartPart(GenerationContext ctx);

  void _writeInto(GenerationContext context,
      {bool withOrderByAndLimit = true}) {
    // whether we need to insert a space before writing the next component
    var needsWhitespace = false;

    void writeWithSpace(
      Component? component,
    ) {
      if (component == null) return;

      if (needsWhitespace) context.writeWhitespace();
      component.writeInto(context);
      needsWhitespace = true;
    }

    writeStartPart(context);
    needsWhitespace = true;

    writeWithSpace(whereExpr);
    writeWithSpace(_groupBy);
    if (withOrderByAndLimit) {
      writeWithSpace(orderByExpr);
      writeWithSpace(limitExpr);
    }

    if (writeReturningClause) {
      if (needsWhitespace) context.writeWhitespace();

      context.buffer.write('RETURNING *');
    }
  }

  @override
  void writeInto(GenerationContext context) {
    _writeInto(context);
  }

  /// Constructs the query that can then be sent to the database executor.
  ///
  /// This is used internally by drift to run the query. Users should use the
  /// other methods explained in the [documentation](https://drift.simonbinder.eu/docs/getting-started/writing_queries/).
  GenerationContext constructQuery() {
    final ctx = GenerationContext.fromDb(database);
    writeInto(ctx);
    ctx.buffer.write(';');
    return ctx;
  }
}

/// Mixin for a [Query] that operates on a single primary table only.
mixin SingleTableQueryMixin<T extends HasResultSet, D> on Query<T, D> {
  /// Makes this statement only include rows that match the [filter].
  ///
  /// For instance, if you have a table users with an id column, you could
  /// select a user with a specific id by using
  /// ```dart
  /// (select(users)..where((u) => u.id.equals(42))).watchSingle()
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
  /// If you want to remove duplicate rows from a query, use the `distinct`
  /// parameter on [DatabaseConnectionUser.select].
  void where(Expression<bool> Function(T tbl) filter) {
    final predicate = filter(table.asDslTable);

    if (whereExpr == null) {
      whereExpr = Where(predicate);
    } else {
      whereExpr = Where(whereExpr!.predicate & predicate);
    }
  }
}

/// Extension for statements on a table.
///
/// This adds the [whereSamePrimaryKey] method as an extension. The query could
/// run on a view, for which [whereSamePrimaryKey] is not defined.
extension QueryTableExtensions<T extends Table, D>
    on SingleTableQueryMixin<T, D> {
  TableInfo<T, D> get _sourceTable => table as TableInfo<T, D>;

  /// Applies a [where] statement so that the row with the same primary key as
  /// [d] will be matched.
  ///
  /// Note that, as far as primary key equality is concerned, `NULL` values are
  /// considered distinct from all values (including other `NULL`s).
  /// This matches sqlite3's behavior of not counting duplicate `NULL`s as a
  /// uniqueness constraint violation for primary keys, but makes it impossible
  /// to find other rows with [whereSamePrimaryKey] if nullable primary keys are
  /// used.
  void whereSamePrimaryKey(Insertable<D> d) {
    final source = _sourceTable;
    assert(
        source.$primaryKey.isNotEmpty,
        'When using Query.whereSamePrimaryKey, which is also called from '
        'DeleteStatement.delete and UpdateStatement.replace, the affected table'
        'must have a primary key. You can either specify a primary implicitly '
        'by making an integer() column autoIncrement(), or by explictly '
        'overriding the primaryKey getter in your table class. You\'ll also '
        'have to re-run the code generation step.\n'
        'Alternatively, if you\'re using DeleteStatement.delete or '
        'UpdateStatement.replace, consider using DeleteStatement.go or '
        'UpdateStatement.write respectively. In that case, you need to use a '
        'custom where statement.');

    final primaryKeyColumns = Map.fromEntries(source.$primaryKey.map((column) {
      return MapEntry(column.$name, column);
    }));

    final updatedFields = d.toColumns(false);
    // Construct a map of [GeneratedColumn] to [Expression] where each column is
    // a primary key and the associated value was extracted from d.
    final primaryKeyValues = Map.fromEntries(updatedFields.entries
            .where((entry) => primaryKeyColumns.containsKey(entry.key)))
        .map((columnName, value) {
      return MapEntry(primaryKeyColumns[columnName]!, value);
    });

    assert(
      primaryKeyValues.values
          .every((value) => value is! Variable || value.value != null),
      'Tried to find a row with a matching primary key that has a null value, '
      'which is not supported. In sqlite3, `NULL` values in a primary key are '
      'considered distinct from all other values (including other `NULL`s), so '
      "drift can't find a matching row for this query. \n"
      'For details, see https://github.com/simolus3/drift/issues/1956#issuecomment-1200502026',
    );

    Expression<bool>? predicate;
    for (final entry in primaryKeyValues.entries) {
      final comparison =
          _Comparison(entry.key, _ComparisonOperator.equal, entry.value);

      if (predicate == null) {
        predicate = comparison;
      } else {
        predicate = predicate & comparison;
      }
    }

    whereExpr = Where(predicate!);
  }
}

/// Mixin to provide the high-level [limit] methods for users.
mixin LimitContainerMixin<T extends HasResultSet, D> on Query<T, D> {
  /// Limits the amount of rows returned by capping them at [limit]. If [offset]
  /// is provided as well, the first [offset] rows will be skipped and not
  /// included in the result.
  void limit(int limit, {int? offset}) {
    limitExpr = Limit(limit, offset);
  }
}
