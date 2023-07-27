part of '../../query_builder.dart';

/// A `SELECT` statement that operates on more than one table.
// this is called JoinedSelectStatement for legacy reasons - we also use it
// when custom expressions are used as result columns. Basically, it stores
// queries that are more complex than SimpleSelectStatement
class JoinedSelectStatement<FirstT extends HasResultSet, FirstD>
    extends Query<FirstT, FirstD>
    with LimitContainerMixin, Selectable<TypedResult>
    implements BaseSelectStatement {
  /// Used internally by drift, users should use [SimpleSelectStatement.join]
  /// instead.
  JoinedSelectStatement(DatabaseConnectionUser database,
      ResultSetImplementation<FirstT, FirstD> table, this._joins,
      [this.distinct = false,
      this._includeMainTableInResult = true,
      this._includeJoinedTablesInResult = true])
      : super(database, table);

  /// Whether to generate a `SELECT DISTINCT` query that will remove duplicate
  /// rows from the result set.
  final bool distinct;
  final bool _includeMainTableInResult;
  final bool _includeJoinedTablesInResult;
  final List<Join> _joins;

  /// All columns that we're selecting from.
  final List<Expression> _selectedColumns = [];

  /// The `AS` aliases generated for each column that isn't from a table.
  ///
  /// Each table column can be uniquely identified by its (potentially aliased)
  /// table and its name. So a column named `id` in a table called `users` would
  /// be written as `users.id AS "users.id"`. These columns are also included in
  /// the map when added through [addColumns], but they have a predicatable name.
  ///
  /// More interestingly, other expressions used as columns will be included
  /// here. They're just named in increasing order, so something like `AS c3`.
  final Map<Expression, String> _columnAliases = {};

  /// The tables this select statement reads from
  @visibleForOverriding
  @Deprecated('Use watchedTables on the generated context')
  Set<ResultSetImplementation> get watchedTables => _queriedTables().toSet();

  @override
  Iterable<(Expression<Object>, String)> get _expandedColumns sync* {
    for (final column in _selectedColumns) {
      yield (column, _columnAliases[column]!);
    }

    for (final table in _queriedTables(true)) {
      for (final column in table.$columns) {
        yield (column, _nameForTableColumn(column));
      }
    }
  }

  @override
  String? _nameForColumn(Expression expression) {
    // Custom column added to this join?
    if (_columnAliases.containsKey(expression)) {
      return _columnAliases[expression];
    }

    // From an added table?
    if (expression is GeneratedColumn) {
      for (final table in _queriedTables(true)) {
        if (table.$columns.contains(expression)) {
          return _nameForTableColumn(expression);
        }
      }
    }

    // Not added to this join
    return null;
  }

  String _nameForTableColumn(GeneratedColumn column,
      {String? generatingForView}) {
    if (generatingForView == column.tableName) {
      return column.$name;
    } else {
      return '${column.tableName}.${column.$name}';
    }
  }

  /// Lists all tables this query reads from.
  ///
  /// If [onlyResults] (defaults to false) is set, only tables that are included
  /// in the result set are returned.
  Iterable<ResultSetImplementation> _queriedTables(
      [bool onlyResults = false]) sync* {
    if (!onlyResults || _includeMainTableInResult) {
      yield table;
    }

    for (final join in _joins) {
      if (onlyResults &&
          !(join.includeInResult ?? _includeJoinedTablesInResult)) continue;

      yield join.table as ResultSetImplementation;
    }
  }

  @override
  void writeStartPart(GenerationContext ctx) {
    // use all columns across all tables as result column for this query
    _selectedColumns.insertAll(
        0, _queriedTables(true).expand((t) => t.$columns).cast<Expression>());

    ctx.hasMultipleTables = true;
    ctx.buffer
      ..write(_beginOfSelect(distinct))
      ..write(' ');

    for (var i = 0; i < _selectedColumns.length; i++) {
      if (i != 0) {
        ctx.buffer.write(', ');
      }

      final column = _selectedColumns[i];
      String chosenAlias;
      if (column is GeneratedColumn) {
        chosenAlias = _nameForTableColumn(column,
            generatingForView: ctx.generatingForView);
      } else {
        chosenAlias = _columnAliases[column]!;
      }

      final chosenAliasEscaped = ctx.dialect.escape(chosenAlias);

      column.writeInto(ctx);
      ctx.buffer
        ..write(' AS ')
        ..write(chosenAliasEscaped);
    }

    ctx.buffer.write(' FROM ');
    ctx.writeResultSet(table);

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
  void where(Expression<bool> predicate) {
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

  /// {@template drift_select_addColumns}
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
  ///  - The docs on expressions: https://drift.simonbinder.eu/docs/getting-started/expressions/
  /// {@endtemplate}
  void addColumns(Iterable<Expression> expressions) {
    for (final expression in expressions) {
      // Otherwise, we generate an alias.
      _columnAliases.putIfAbsent(expression, () {
        // Only add the column if it hasn't been added yet - it's fine if the
        // same column is added multiple times through the Dart API, they will
        // read from the same SQL column internally.
        _selectedColumns.add(expression);

        if (expression is GeneratedColumn) {
          return _nameForTableColumn(expression);
        } else {
          return 'c${_columnAliases.length}';
        }
      });
    }
  }

  /// Adds more joined tables to this [JoinedSelectStatement].
  ///
  /// Always returns the same instance.
  ///
  /// See also:
  ///  - https://drift.simonbinder.eu/docs/advanced-features/joins/#joins
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
  void groupBy(Iterable<Expression> expressions, {Expression<bool>? having}) {
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
        .asyncMapPerSubscription((rows) => _mapResponse(rows));
  }

  @override
  Future<List<TypedResult>> get() async {
    final ctx = constructQuery();
    final raw = await _getRaw(ctx);
    return _mapResponse(raw);
  }

  Future<List<Map<String, Object?>>> _getRaw(GenerationContext ctx) {
    return ctx.executor!.doWhenOpened((e) async {
      try {
        return await e.runSelect(ctx.sql, ctx.boundVariables);
      } catch (e, s) {
        final foundTables = <String>{};
        for (final table in _queriedTables()) {
          if (!foundTables.add(table.aliasedName)) {
            _warnAboutDuplicate(e, s, table);
          }
        }

        rethrow;
      }
    });
  }

  @override
  Future<TypedResult> _mapRow(Map<String, Object?> row) async {
    final readTables = <ResultSetImplementation, dynamic>{};

    for (final table in _queriedTables(true)) {
      final prefix = '${table.aliasedName}.';
      // if all columns of this table are null, skip the table
      if (table.$columns.any((c) => row[prefix + c.$name] != null)) {
        readTables[table] =
            await table.map(row, tablePrefix: table.aliasedName);
      }
    }

    final driftRow = QueryRow(row, database);
    return TypedResult(
        readTables, driftRow, _LazyExpressionMap(_columnAliases, driftRow));
  }

  Future<List<TypedResult>> _mapResponse(List<Map<String, Object?>> rows) {
    return Future.wait(rows.map(_mapRow));
  }

  Never _warnAboutDuplicate(
      dynamic cause, StackTrace trace, ResultSetImplementation table) {
    throw DriftWrappedException(
      message: 'This query contained the table ${table.entityName} more than '
          'once. Is this a typo? \n'
          'If you need a join that includes the same table more than once, you '
          'need to alias() at least one table. See https://drift.simonbinder.eu/queries/joins#aliases '
          'for an example.',
      cause: cause,
      trace: trace,
    );
  }
}

/// A map responsible for reading typed values for a [TypedResult].
///
/// In a [JoinedSelectStatement], every column of every table is read and
/// interpreted as a result, even if it's never used later. For joins with lots
/// of tables, this can quickly become very expensive.
///
/// So, to stay compatible with the [Map] interface but also be more efficient,
/// we now use this implementation to lazily do the type mapping when a column
/// is first read. There's a builtin cache so columns accessed a lot aren't
/// read multiple times, but using this map we can generally speed things up
/// when joins with lots of columns are used.
class _LazyExpressionMap extends UnmodifiableMapBase<Expression, Object?> {
  final Map<Expression, String> _columnAliases;
  final QueryRow _rawData;

  final Map<Expression, Object?> _cachedData = {};

  _LazyExpressionMap(this._columnAliases, this._rawData);

  @override
  Object? operator [](Object? key) {
    if (!containsKey(key) || key is! Expression) return null;

    return _cachedData.putIfAbsent(key, () {
      return _rawData.readNullableWithType(
          key.driftSqlType, _columnAliases[key]!);
    });
  }

  @override
  Iterable<Expression> get keys => _columnAliases.keys;

  @override
  bool containsKey(Object? key) => _columnAliases.containsKey(key);
}
