part of '../../query_builder.dart';

/// A `SELECT` statement that operates on more than one table.
class JoinedSelectStatement<FirstT extends Table, FirstD extends DataClass>
    extends Query<FirstT, FirstD>
    with LimitContainerMixin, Selectable<TypedResult> {
  /// Whether to generate a `SELECT DISTINCT` query that will remove duplicate
  /// rows from the result set.
  final bool distinct;

  /// Used internally by moor, users should use [SimpleSelectStatement.join]
  /// instead.
  JoinedSelectStatement(
      QueryEngine database, TableInfo<FirstT, FirstD> table, this._joins,
      [this.distinct = false])
      : super(database, table);

  final List<Join> _joins;

  /// The tables this select statement reads from
  @visibleForOverriding
  Set<TableInfo> get watchedTables => _tables.toSet();

  // fixed order to make testing easier
  Iterable<TableInfo> get _tables =>
      <TableInfo>[table].followedBy(_joins.map((j) => j.table));

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.hasMultipleTables = true;
    ctx.buffer..write(_beginOfSelect(distinct))..write(' ');

    var isFirst = true;
    for (var table in _tables) {
      for (var column in table.$columns) {
        if (!isFirst) {
          ctx.buffer.write(', ');
        }

        // We run into problems when two tables have a column with the same name
        // as we then wouldn't know which column is which. So, we create a
        // column alias that matches what is expected by the mapping function
        // in _getWithQuery by prefixing the table name.
        // We might switch to parsing via the index of the column in a row in
        // the future, but that's the solution for now.

        column.writeInto(ctx);
        ctx.buffer.write(' AS "');
        column.writeInto(ctx, ignoreEscape: true);
        ctx.buffer.write('"');

        isFirst = false;
      }
    }

    ctx.buffer.write(' FROM ${table.tableWithAlias}');

    if (_joins.isNotEmpty) {
      ctx.writeWhitespace();

      for (var i = 0; i < _joins.length; i++) {
        if (i != 0) ctx.writeWhitespace();

        _joins[i].writeInto(ctx);
      }
    }
  }

  /// Applies the [predicate] as the where clause, which will be used to filter
  /// results.
  ///
  /// The clause should only refer to columns defined in one of the tables
  /// specified during [SimpleSelectStatement.join].
  ///
  /// With the example of a todos table which refers to categories, we can write
  /// something like
  /// ```dart
  /// final query = select(todos)
  /// .join([
  ///   leftOuterJoin(categories, categories.id.equalsExp(todos.category)),
  /// ])
  /// ..where(and(todos.name.like("%Important"), categories.name.equals("Work")));
  /// ```
  void where(Expression<bool, BoolType> predicate) {
    if (whereExpr == null) {
      whereExpr = Where(predicate);
    } else {
      whereExpr = Where(whereExpr.predicate & predicate);
    }
  }

  /// Orders the results of this statement by the ordering [terms].
  void orderBy(List<OrderingTerm> terms) {
    orderByExpr = OrderBy(terms);
  }

  @override
  Stream<List<TypedResult>> watch() {
    final ctx = constructQuery();
    final fetcher = QueryStreamFetcher<List<TypedResult>>(
      readsFrom: watchedTables,
      fetchData: () => _getWithQuery(ctx),
      key: StreamKey(ctx.sql, ctx.boundVariables, TypedResult),
    );

    return database.createStream(fetcher);
  }

  @override
  Future<List<TypedResult>> get() async {
    final ctx = constructQuery();
    return _getWithQuery(ctx);
  }

  Future<List<TypedResult>> _getWithQuery(GenerationContext ctx) async {
    final results = await ctx.executor.doWhenOpened((e) async {
      try {
        return await e.runSelect(ctx.sql, ctx.boundVariables);
      } catch (e, s) {
        final foundTables = <String>{};
        for (var table in _tables) {
          if (!foundTables.add(table.$tableName)) {
            _warnAboutDuplicate(e, s, table);
          }
        }

        rethrow;
      }
    });

    final tables = _tables;

    return results.map((row) {
      final map = <TableInfo, dynamic>{};

      for (var table in tables) {
        final prefix = '${table.$tableName}.';
        // if all columns of this table are null, skip the table
        if (table.$columns.any((c) => row[prefix + c.$name] != null)) {
          map[table] = table.map(row, tablePrefix: table.$tableName);
        } else {
          map[table] = null;
        }
      }

      return TypedResult(map, QueryRow(row, database));
    }).toList();
  }

  @alwaysThrows
  void _warnAboutDuplicate(dynamic cause, StackTrace trace, TableInfo table) {
    throw MoorWrappedException(
      message:
          'This query contained the table ${table.actualTableName} more than '
          'once. Is this a typo? \n'
          'If you need a join that includes the same table more than once, you '
          'need to alias() at least one table. See https://moor.simonbinder.eu/queries/joins#aliases '
          'for an example.',
      cause: cause,
      trace: trace,
    );
  }
}
