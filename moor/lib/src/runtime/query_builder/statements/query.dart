part of '../query_builder.dart';

/// Statement that operates with data that already exists (select, delete,
/// update).
abstract class Query<T extends Table, D extends DataClass> {
  /// The database this statement should be sent to.
  @protected
  QueryEngine database;

  /// The (main) table this query operates on.
  TableInfo<T, D> table;

  /// Used internally by moor. Users should use the appropriate methods on
  /// [QueryEngine] instead.
  Query(this.database, this.table);

  /// The `WHERE` clause for this statement
  @protected
  Where whereExpr;

  /// The `ORDER BY` clause for this statement
  @protected
  OrderBy orderByExpr;

  /// The `LIMIT` clause for this statement.
  @protected
  Limit limitExpr;

  /// Subclasses must override this and write the part of the statement that
  /// comes before the where and limit expression..
  @visibleForOverriding
  void writeStartPart(GenerationContext ctx);

  /// Constructs the query that can then be sent to the database executor.
  ///
  /// This is used internally by moor to run the query. Users should use the
  /// other methods explained in the [documentation][moor-docs].
  /// [moor-docs]: https://moor.simonbinder.eu/docs/getting-started/writing_queries/
  GenerationContext constructQuery() {
    final ctx = GenerationContext.fromDb(database);
    var needsWhitespace = false;

    writeStartPart(ctx);
    needsWhitespace = true;

    if (whereExpr != null) {
      if (needsWhitespace) ctx.writeWhitespace();

      whereExpr.writeInto(ctx);
      needsWhitespace = true;
    }

    if (orderByExpr != null) {
      if (needsWhitespace) ctx.writeWhitespace();

      orderByExpr.writeInto(ctx);
      needsWhitespace = true;
    }

    if (limitExpr != null) {
      if (needsWhitespace) ctx.writeWhitespace();

      limitExpr.writeInto(ctx);
      needsWhitespace = true;
    }

    ctx.buffer.write(';');

    return ctx;
  }
}

/// Abstract class for queries which can return one-time values or a stream
/// of values.
abstract class Selectable<T> {
  /// Executes this statement and returns the result.
  Future<List<T>> get();

  /// Creates an auto-updating stream of the result that emits new items
  /// whenever any table used in this statement changes.
  Stream<List<T>> watch();

  /// Executes this statement, like [get], but only returns one value. If the
  /// result too many values, this method will throw. If no row is returned,
  /// `null` will be returned instead.
  ///
  /// {@template moor_single_query_expl}
  /// Be aware that this operation won't put a limit clause on this statement,
  /// if that's needed you would have to do use [SimpleSelectStatement.limit]:
  /// ```dart
  /// Future<TodoEntry> loadMostImportant() {
  ///   return (select(todos)
  ///    ..orderBy([(t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc)])
  ///    ..limit(1)
  ///   ).getSingle();
  /// }
  /// ```
  /// You should only use this method if you know the query won't have more than
  /// one row, for instance because you used `limit(1)` or you know the `where`
  /// clause will only allow one row.
  /// {@endtemplate}
  Future<T> getSingle() async {
    final list = await get();
    final iterator = list.iterator;

    if (!iterator.moveNext()) {
      return null;
    }
    final element = iterator.current;
    if (iterator.moveNext()) {
      throw StateError('Expected exactly one result, but found more than one!');
    }

    return element;
  }

  /// Creates an auto-updating stream of this statement, similar to [watch].
  /// However, it is assumed that the query will only emit one result, so
  /// instead of returning a [Stream<List<T>>], this returns a [Stream<T>]. If
  /// the query emits more than one row at some point, an error will be emitted
  /// to the stream instead. If the query emits zero rows at some point, `null`
  /// will be added to the stream instead.
  ///
  /// {@macro moor_single_query_expl}
  Stream<T> watchSingle() {
    return watch().transform(singleElements());
  }

  /// Maps this selectable by the [mapper] function.
  ///
  /// Each entry emitted by this [Selectable] will be transformed by the
  /// [mapper] and then emitted to the selectable returned.
  Selectable<N> map<N>(N Function(T) mapper) {
    return _MappedSelectable<T, N>(this, mapper);
  }
}

class _MappedSelectable<S, T> extends Selectable<T> {
  final Selectable<S> _source;
  final T Function(S) _mapper;

  _MappedSelectable(this._source, this._mapper);

  @override
  Future<List<T>> get() {
    return _source.get().then(_mapResults);
  }

  @override
  Stream<List<T>> watch() {
    return _source.watch().map(_mapResults);
  }

  List<T> _mapResults(List<S> results) => results.map(_mapper).toList();
}

mixin SingleTableQueryMixin<T extends Table, D extends DataClass>
    on Query<T, D> {
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
  ///  - The docs on [expressions](https://moor.simonbinder.eu/docs/getting-started/expressions/),
  ///    which explains how to express most SQL expressions in Dart.
  /// If you want to remove duplicate rows from a query, use the `distinct`
  /// parameter on [QueryEngine.select].
  void where(Expression<bool, BoolType> filter(T tbl)) {
    final predicate = filter(table.asDslTable);

    if (whereExpr == null) {
      whereExpr = Where(predicate);
    } else {
      whereExpr = Where(and(whereExpr.predicate, predicate));
    }
  }

  /// Applies a [where] statement so that the row with the same primary key as
  /// [d] will be matched.
  void whereSamePrimaryKey(Insertable<D> d) {
    assert(
        table.$primaryKey != null && table.$primaryKey.isNotEmpty,
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

    final primaryKeys = table.$primaryKey.map((c) => c.$name);

    final updatedFields = table.entityToSql(d.createCompanion(false));
    // Extract values of the primary key as they are needed for the where clause
    final primaryKeyValues = Map.fromEntries(updatedFields.entries
        .where((entry) => primaryKeys.contains(entry.key)));

    Expression<bool, BoolType> predicate;
    for (var entry in primaryKeyValues.entries) {
      // custom expression that references the column
      final columnExpression = CustomExpression(entry.key);
      final comparison =
          _Comparison(columnExpression, _ComparisonOperator.equal, entry.value);

      if (predicate == null) {
        predicate = comparison;
      } else {
        predicate = and(predicate, comparison);
      }
    }

    whereExpr = Where(predicate);
  }
}

/// Mixin to provide the high-level [limit] methods for users.
mixin LimitContainerMixin<T extends Table, D extends DataClass> on Query<T, D> {
  /// Limits the amount of rows returned by capping them at [limit]. If [offset]
  /// is provided as well, the first [offset] rows will be skipped and not
  /// included in the result.
  void limit(int limit, {int offset}) {
    limitExpr = Limit(limit, offset);
  }
}
