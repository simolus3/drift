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

  @override
  void writeInto(GenerationContext context) {
    // whether we need to insert a space before writing the next component
    var needsWhitespace = false;

    void writeWithSpace(Component? component) {
      if (component == null) return;

      if (needsWhitespace) context.writeWhitespace();
      component.writeInto(context);
      needsWhitespace = true;
    }

    writeStartPart(context);
    needsWhitespace = true;

    writeWithSpace(whereExpr);
    writeWithSpace(_groupBy);
    writeWithSpace(orderByExpr);
    writeWithSpace(limitExpr);

    if (writeReturningClause) {
      if (needsWhitespace) context.writeWhitespace();

      context.buffer.write('RETURNING *');
    }
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

/// [Selectable] methods for returning multiple results.
///
/// Useful for refining the return type of a query, while still delegating
/// whether to [get] or [watch] results to the consuming code.
///
/// {@template drift_multi_selectable_example}
/// ```dart
/// /// Retrieve a page of [Todo]s.
/// MultiSelectable<Todo> pageOfTodos(int page, {int pageSize = 10}) {
///   return select(todos)..limit(pageSize, offset: page);
/// }
/// pageOfTodos(1).get();
/// pageOfTodos(1).watch();
/// ```
/// {@endtemplate}
///
/// See also: [SingleSelectable] and [SingleOrNullSelectable] for exposing
/// single value methods.
abstract class MultiSelectable<T> {
  /// Executes this statement and returns the result.
  Future<List<T>> get();

  /// Creates an auto-updating stream of the result that emits new items
  /// whenever any table used in this statement changes.
  Stream<List<T>> watch();
}

/// [Selectable] methods for returning or streaming single,
/// non-nullable results.
///
/// Useful for refining the return type of a query, while still delegating
/// whether to [getSingle] or [watchSingle] results to the consuming code.
///
/// {@template drift_single_selectable_example}
/// ```dart
/// // Retrieve a todo known to exist.
/// SingleSelectable<Todo> entryById(int id) {
///   return select(todos)..where((t) => t.id.equals(id));
/// }
/// final idGuaranteedToExist = 10;
/// entryById(idGuaranteedToExist).getSingle();
/// entryById(idGuaranteedToExist).watchSingle();
/// ```
/// {@endtemplate}
///
/// See also: [MultiSelectable] for exposing multi-value methods and
/// [SingleOrNullSelectable] for exposing nullable value methods.
abstract class SingleSelectable<T> {
  /// Executes this statement, like [Selectable.get], but only returns one
  /// value. the query returns no or too many rows, the returned future will
  /// complete with an error.
  ///
  /// {@template drift_single_query_expl}
  /// Be aware that this operation won't put a limit clause on this statement,
  /// if that's needed you would have to do use [SimpleSelectStatement.limit]:
  /// ```dart
  /// Future<TodoEntry> loadMostImportant() {
  ///   return (select(todos)
  ///    ..orderBy([(t) =>
  ///       OrderingTerm(expression: t.priority, mode: OrderingMode.desc)])
  ///    ..limit(1)
  ///   ).getSingle();
  /// }
  /// ```
  /// You should only use this method if you know the query won't have more than
  /// one row, for instance because you used `limit(1)` or you know the `where`
  /// clause will only allow one row.
  /// {@endtemplate}
  ///
  /// See also: [Selectable.getSingleOrNull], which returns `null` instead of
  /// throwing if the query completes with no rows.
  Future<T> getSingle();

  /// Creates an auto-updating stream of this statement, similar to
  /// [Selectable.watch]. However, it is assumed that the query will only emit
  /// one result, so instead of returning a `Stream<List<T>>`, this returns a
  /// `Stream<T>`. If, at any point, the query emits no or more than one rows,
  /// an error will be added to the stream instead.
  ///
  /// {@macro drift_single_query_expl}
  Stream<T> watchSingle();
}

/// [Selectable] methods for returning or streaming single,
/// nullable results.
///
/// Useful for refining the return type of a query, while still delegating
/// whether to [getSingleOrNull] or [watchSingleOrNull] result to the
/// consuming code.
///
/// {@template drift_single_or_null_selectable_example}
///```dart
/// // Retrieve a todo from an external link that may not be valid.
/// SingleOrNullSelectable<Todo> entryFromExternalLink(int id) {
///   return select(todos)..where((t) => t.id.equals(id));
/// }
/// final idFromEmailLink = 100;
/// entryFromExternalLink(idFromEmailLink).getSingleOrNull();
/// entryFromExternalLink(idFromEmailLink).watchSingleOrNull();
/// ```
/// {@endtemplate}
///
/// See also: [MultiSelectable] for exposing multi-value methods and
/// [SingleSelectable] for exposing non-nullable value methods.
abstract class SingleOrNullSelectable<T> {
  /// Executes this statement, like [Selectable.get], but only returns one
  /// value. If the result too many values, this method will throw. If no
  /// row is returned, `null` will be returned instead.
  ///
  /// {@macro drift_single_query_expl}
  ///
  /// See also: [Selectable.getSingle], which can be used if the query will
  /// always evaluate to exactly one row.
  Future<T?> getSingleOrNull();

  /// Creates an auto-updating stream of this statement, similar to
  /// [Selectable.watch]. However, it is assumed that the query will only
  /// emit one result, so instead of returning a `Stream<List<T>>`, this
  /// returns a `Stream<T?>`. If the query emits more than one row at
  /// some point, an error will be emitted to the stream instead.
  /// If the query emits zero rows at some point, `null` will be added
  /// to the stream instead.
  ///
  /// {@macro drift_single_query_expl}
  Stream<T?> watchSingleOrNull();
}

/// Abstract class for queries which can return one-time values or a stream
/// of values.
///
/// If you want to make your query consumable as either a [Future] or a
/// [Stream], you can refine your return type using one of Selectable's
/// base classes:
///
/// {@macro drift_multi_selectable_example}
/// {@macro drift_single_selectable_example}
/// {@macro drift_single_or_null_selectable_example}
abstract class Selectable<T>
    implements
        MultiSelectable<T>,
        SingleSelectable<T>,
        SingleOrNullSelectable<T> {
  @override
  Future<List<T>> get();

  @override
  Stream<List<T>> watch();

  @override
  Future<T> getSingle() async {
    return (await get()).single;
  }

  @override
  Stream<T> watchSingle() {
    return watch().transform(singleElements());
  }

  @override
  Future<T?> getSingleOrNull() async {
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

  @override
  Stream<T?> watchSingleOrNull() {
    return watch().transform(singleElementsOrNull());
  }

  /// Maps this selectable by the [mapper] function.
  ///
  /// Each entry emitted by this [Selectable] will be transformed by the
  /// [mapper] and then emitted to the selectable returned.
  Selectable<N> map<N>(N Function(T) mapper) {
    return _MappedSelectable<T, N>(this, mapper);
  }

  /// Maps this selectable by the [mapper] function.
  ///
  /// Like [map] just async.
  Selectable<N> asyncMap<N>(Future<N> Function(T) mapper) {
    return _AsyncMappedSelectable<T, N>(this, mapper);
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

class _AsyncMappedSelectable<S, T> extends Selectable<T> {
  final Selectable<S> _source;
  final Future<T> Function(S) _mapper;

  _AsyncMappedSelectable(this._source, this._mapper);

  @override
  Future<List<T>> get() {
    return _source.get().then(_mapResults);
  }

  @override
  Stream<List<T>> watch() {
    return _source.watch().asyncMap(_mapResults);
  }

  Future<List<T>> _mapResults(List<S> results) async =>
      [for (final result in results) await _mapper(result)];
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
