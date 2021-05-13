part of '../../query_builder.dart';

/// A `SELECT` statement that operates on more than one table.
// this is called JoinedSelectStatement for legacy reasons - we also use it
// when custom expressions are used as result columns. Basically, it stores
// queries that are more complex than SimpleSelectStatement
class JoinedSelectStatement<FirstT extends Table, FirstD>
    extends Query<FirstT, FirstD>
    with LimitContainerMixin, Selectable<TypedResult>
    implements BaseSelectStatement {
  /// Used internally by moor, users should use [SimpleSelectStatement.join]
  /// instead.
  JoinedSelectStatement(DatabaseConnectionUser database,
      TableInfo<FirstT, FirstD> table, this._joins,
      [this.distinct = false, this._includeMainTableInResult = true])
      : super(database, table);

  /// Whether to generate a `SELECT DISTINCT` query that will remove duplicate
  /// rows from the result set.
  final bool distinct;
  final bool _includeMainTableInResult;
  final List<Join> _joins;

  /// All columns that we're selecting from.
  final List<Expression> _selectedColumns = [];

  /// The `AS` aliases generated for each column that isn't from a table.
  ///
  /// Each table column can be uniquely identified by its (potentially aliased)
  /// table and its name. So a column named `id` in a table called `users` would
  /// be written as `users.id AS "users.id"`. These columns will NOT be written
  /// into this map.
  ///
  /// Other expressions used as columns will be included here. There just named
  /// in increasing order, so something like `AS c3`.
  final Map<Expression, String> _columnAliases = {};

  /// The tables this select statement reads from
  @visibleForOverriding
  @Deprecated('Use watchedTables on the generated context')
  Set<TableInfo> get watchedTables => _queriedTables().toSet();

  @override
  int get _returnedColumnCount {
    return _joins.fold(_selectedColumns.length, (prev, join) {
      if (join.includeInResult) {
        return prev + join.table.$columns.length;
      }
      return prev;
    });
  }

  /// Lists all tables this query reads from.
  ///
  /// If [onlyResults] (defaults to false) is set, only tables that are included
  /// in the result set are returned.
  Iterable<TableInfo> _queriedTables([bool onlyResults = false]) sync* {
    if (!onlyResults || _includeMainTableInResult) {
      yield table;
    }

    for (final join in _joins) {
      if (onlyResults && !join.includeInResult) continue;

      yield join.table;
    }
  }

  @override
  void writeStartPart(GenerationContext ctx) {
    // use all columns across all tables as result column for this query
    _selectedColumns.insertAll(
        0, _queriedTables(true).expand((t) => t.$columns).cast<Expression>());

    ctx.hasMultipleTables = true;
    ctx.buffer..write(_beginOfSelect(distinct))..write(' ');

    for (var i = 0; i < _selectedColumns.length; i++) {
      if (i != 0) {
        ctx.buffer.write(', ');
      }

      final column = _selectedColumns[i];
      String chosenAlias;
      if (column is GeneratedColumn) {
        chosenAlias = '${column.tableName}.${column.$name}';
      } else {
        chosenAlias = 'c$i';
      }
      _columnAliases[column] = chosenAlias;

      column.writeInto(ctx);
      ctx.buffer..write(' AS "')..write(chosenAlias)..write('"');
    }

    ctx.buffer.write(' FROM ${table.tableWithAlias}');
    ctx.watchedTables.add(table);

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
  /// ..where(todos.name.like("%Important") & categories.name.equals("Work"));
  /// ```
  void where(Expression<bool?> predicate) {
    if (whereExpr == null) {
      whereExpr = Where(predicate);
    } else {
      whereExpr = Where(whereExpr!.predicate & predicate);
    }
  }

  /// Orders the results of this statement by the ordering [terms].
  void orderBy(List<OrderingTerm> terms) {
    orderByExpr = OrderBy(terms);
  }

  /// {@template moor_select_addColumns}
  /// Adds a custom expression to the query.
  ///
  /// The database will evaluate the [Expression] for each row found for this
  /// query. The value of the expression can be extracted from the [TypedResult]
  /// by passing it to [TypedResult.read].
  ///
  /// As an example, we could calculate the length of a column on the database:
  /// ```dart
  /// final contentLength = todos.content.length;
  /// final results = await select(todos).addColumns([contentLength]).get();
  ///
  /// // we can now read the result of a column added to addColumns
  /// final lengthOfFirst = results.first.read(contentLength);
  /// ```
  ///
  /// See also:
  ///  - The docs on expressions: https://moor.simonbinder.eu/docs/getting-started/expressions/
  /// {@endtemplate}
  void addColumns(Iterable<Expression> expressions) {
    _selectedColumns.addAll(expressions);
  }

  /// Adds more joined tables to this [JoinedSelectStatement].
  ///
  /// Always returns the same instance.
  ///
  /// See also:
  ///  - https://moor.simonbinder.eu/docs/advanced-features/joins/#joins
  ///  - [SimpleSelectStatement.join], which is used for the first join
  ///  - [innerJoin], [leftOuterJoin] and [crossJoin], which can be used to
  ///  construct a [Join].
  ///  - [DatabaseConnectionUser.alias], which can be used to build statements
  ///  that refer to the same table multiple times.
  // ignore: avoid_returning_this
  JoinedSelectStatement join(List<Join> joins) {
    _joins.addAll(joins);
    return this;
  }

  /// Groups the result by values in [expressions].
  ///
  /// An optional [having] attribute can be set to exclude certain groups.
  void groupBy(Iterable<Expression> expressions, {Expression<bool?>? having}) {
    _groupBy = GroupBy._(expressions.toList(), having);
  }

  @override
  Stream<List<TypedResult>> watch() {
    final ctx = constructQuery();
    final fetcher = QueryStreamFetcher(
      readsFrom: TableUpdateQuery.onAllTables(ctx.watchedTables),
      fetchData: () => _getRaw(ctx),
      key: StreamKey(ctx.sql, ctx.boundVariables),
    );

    return database
        .createStream(fetcher)
        .map((rows) => _mapResponse(ctx, rows));
  }

  @override
  Future<List<TypedResult>> get() async {
    final ctx = constructQuery();
    final raw = await _getRaw(ctx);
    return _mapResponse(ctx, raw);
  }

  Future<List<Map<String, Object?>>> _getRaw(GenerationContext ctx) {
    return ctx.executor!.doWhenOpened((e) async {
      try {
        return await e.runSelect(ctx.sql, ctx.boundVariables);
      } catch (e, s) {
        final foundTables = <String>{};
        for (final table in _queriedTables()) {
          if (!foundTables.add(table.$tableName)) {
            _warnAboutDuplicate(e, s, table);
          }
        }

        rethrow;
      }
    });
  }

  List<TypedResult> _mapResponse(
      GenerationContext ctx, List<Map<String, Object?>> rows) {
    return rows.map((row) {
      final readTables = <TableInfo, dynamic>{};
      final readColumns = <Expression, dynamic>{};

      for (final table in _queriedTables(true)) {
        final prefix = '${table.$tableName}.';
        // if all columns of this table are null, skip the table
        if (table.$columns.any((c) => row[prefix + c.$name] != null)) {
          readTables[table] = table.map(row, tablePrefix: table.$tableName);
        }
      }

      for (final aliasedColumn in _columnAliases.entries) {
        final expr = aliasedColumn.key;
        final value = row[aliasedColumn.value];

        final type = expr.findType(ctx.typeSystem);
        readColumns[expr] = type.mapFromDatabaseResponse(value);
      }

      return TypedResult(readTables, QueryRow(row, database), readColumns);
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
