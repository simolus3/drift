import 'package:meta/meta.dart';

import '../../connection/result_set.dart';
import '../../connection/streams/store.dart';
import '../../connection/streams/update_rules.dart';
import '../../database/connection_user.dart';
import '../../database/selectable.dart';
import '../../dsl/table.dart';
import '../clauses/group_by.dart';
import '../clauses/limit.dart';
import '../clauses/order_by.dart';
import '../clauses/where.dart';
import '../compiler.dart';
import '../expressions/boolean.dart';
import '../expressions/expression.dart';
import '../results.dart';
import '../schema/result_set.dart';
import 'statement.dart';
import 'query.dart';

/// Common class for generated `SELECT` statements on databases.
@optionalTypeArgs
sealed class BaseSelectStatement<
  Self extends BaseSelectStatement<Self, Row>,
  Row
>
    extends SqlStatement
    with Selectable<Row> {
  /// The [ResultSetStructure] for this statement, describing columns we expect
  /// it to return.
  ///
  /// The structure allows looking up indices for expressions added to this
  /// statement, as well as column ranges for tables.
  final ResultSetStructure structure = ResultSetStructure();

  /// Whether to add a `DISTINCT` clause to this select, meaning that duplicate
  /// rows would be removed.
  final bool distinct;

  /// All tables that this statement selects from.
  final List<FromClauseElement> from = [];

  /// The filtering `WHERE` clause of this select statement.
  WhereClause? whereClause;

  /// The optional `GROUP BY` clause for this select statement.
  GroupBy? groupByClause;

  /// The optional `ORDER BY` clause for this select statement.
  OrderBy? orderByClause;

  /// The optional `LIMIT` clause restricting the amount of rows returned by
  /// this statement.
  Limit? limitClause;

  /// All [CompoundSelect] statements that have been added to this select
  /// statement using [union], [unionAll], [except] and [intersect].
  final List<CompoundSelect> compounds = [];

  /// The database this statement should be sent to.
  final DatabaseConnectionUser _database;

  BaseSelectStatement(this._database, {this.distinct = false});

  ColumnPosition get _nextPosition {
    final index = structure.expressions.length;
    return ColumnPosition(index);
  }

  /// Adds a column to this query.
  ///
  /// The column will be evaluated for each row of the expression. To read the
  /// result of the expression in a row, use [DriftRow.read].
  SelectStatement addColumn(Expression expression) {
    return _asSelectStatement()
      ..structure.expressions[expression] ??= _nextPosition;
  }

  /// Adds multiple columns to this query.
  ///
  /// The column will be evaluated for each row of the expression. To read the
  /// result of the expression in a row, use [DriftRow.read].
  SelectStatement addColumns(Iterable<Expression> expressions) {
    final stmt = _asSelectStatement();
    for (final expression in expressions) {
      stmt.structure.expressions[expression] ??= _nextPosition;
    }
    return stmt;
  }

  /// Adds all columns from [ResultSet] to this query.
  @internal
  void addResultSet(ResultSet resultSet) {
    if (structure.tables.containsKey(resultSet)) {
      throw StateError(
        'Result set $resultSet has been added to select multiple times, please use an alias',
      );
    }

    final positions = <ColumnPosition>[];
    for (final column in resultSet.columns) {
      final columnPosition = _nextPosition;
      positions.add(columnPosition);
      structure.expressions[column] = columnPosition;
    }

    structure.tables[resultSet] = positions;
  }

  /// Adds [table] to this query using an `INNER JOIN` operator.
  SelectStatement innerJoin(
    ResultSetDsl table, {
    Expression<bool>? on,
    bool? includeInResult,
  }) {
    return _withAddedJoin(
      Join.inner(table, on: on, includeInResult: includeInResult),
    );
  }

  /// Adds [table] to this query using a `LEFT OUTER JOIN` operator.
  SelectStatement leftOuter(
    ResultSetDsl table, {
    Expression<bool>? on,
    bool? includeInResult,
  }) {
    return _withAddedJoin(
      Join.leftOuter(table, on: on, includeInResult: includeInResult),
    );
  }

  /// Adds [table] to this query using a `CROSS JOIN` operator.
  SelectStatement cross(ResultSetDsl table, {bool? includeInResult}) {
    return _withAddedJoin(Join.cross(table, includeInResult: includeInResult));
  }

  /// Groups the result by values in [expressions].
  ///
  /// An optional [having] attribute can be set to exclude certain groups.
  Self groupBy(Iterable<Expression> expressions, {Expression<bool>? having}) {
    groupByClause = GroupBy(expressions.toList(), having: having);
    return _asSelf();
  }

  /// Limits the amount of rows returned by capping them at [limit]. If [offset]
  /// is provided as well, the first [offset] rows will be skipped and not
  /// included in the result.
  Self limit(int limit, {int? offset}) {
    limitClause = Limit(limit, offset);
    return _asSelf();
  }

  /// Appends the [other] statement as a `UNION` clause after this query.
  ///
  /// The database will run both queries and return all rows involved in either
  /// query, removing duplicates. For this to work, this and [other] must have
  /// compatible columns.
  ///
  /// The [other] query must not include a `LIMIT` or a `ORDER BY` clause.
  /// Compound statements can only contain a single `LIMIT` and `ORDER BY`
  /// clause at the end, which is set on the first statement (on which
  /// [union] is called). Also, the [other] statement must not contain compound
  /// parts on its own.
  ///
  /// As an example, consider a `todos` table of todo items referencing a
  /// `categories` table used to group them. With that structure, it's possible
  /// to compute the amount of todo items in each category, as well as the
  /// amount of todo items not in a category in a single query:
  ///
  /// ```dart
  ///   final count = subqueryExpression<int>(selectOnly(todos)
  ///    .addColumns([countAll()])
  ///    .where(todos.category.equalsExp(categories.id)));
  ///  final countWithoutCategory = subqueryExpression<int>(db.selectOnly(todos)
  ///        .addColumns([countAll()])
  ///        .where(todos.category.isNull()));
  ///
  ///  final query = db.selectOnly(db.categories)
  ///    .addColumns([db.categories.description, count])
  ///    .groupBy([categories.id]);
  ///    .union(db.selectExpressions([const Constant<String>(null), countWithoutCategory]));
  /// ```
  SelectStatement union(BaseSelectStatement other) {
    return _asSelectStatement().._addCompound(CompoundOperator.union, other);
  }

  /// Appends the [other] statement as a `UNION ALL` clause after this query.
  ///
  /// The database will run both queries and return all rows involved in either
  /// query. For this to work, this and [other] must have compatible columns.
  ///
  /// The [other] query must not include a `LIMIT` or a `ORDER BY` clause.
  /// Compound statements can only contain a single `LIMIT` and `ORDER BY`
  /// clause at the end, which is set on the first statement (on which
  /// [unionAll] is called). Also, the [other] statement must not contain
  /// compound parts on its own.
  ///
  /// As an example, consider a `todos` table of todo items referencing a
  /// `categories` table used to group them. With that structure, it's possible
  /// to compute the amount of todo items in each category, as well as the
  /// amount of todo items not in a category in a single query:
  ///
  /// ```dart
  ///   final count = subqueryExpression<int>(selectOnly(todos)
  ///    .addColumns([countAll()])
  ///    .where(todos.category.equalsExp(categories.id)));
  ///  final countWithoutCategory = subqueryExpression<int>(db.selectOnly(todos)
  ///        .addColumns([countAll()])
  ///        .where(todos.category.isNull()));
  ///
  ///  final query = db.selectOnly(db.categories)
  ///    .addColumns([db.categories.description, count])
  ///    .groupBy([categories.id]);
  ///    .unionAll(db.selectExpressions([const Constant<String>(null), countWithoutCategory]));
  /// ```
  SelectStatement unionAll(BaseSelectStatement other) {
    return _asSelectStatement().._addCompound(CompoundOperator.unionAll, other);
  }

  /// Appends the [other] statement as a `EXCEPT` clause after this query.
  ///
  /// The database will run both queries and return all rows of the first query
  /// that were not returned by [other]. For this to work, this and [other] must
  /// have compatible columns.
  ///
  /// The [other] query must not include a `LIMIT` or a `ORDER BY` clause.
  /// Compound statements can only contain a single `LIMIT` and `ORDER BY`
  /// clause at the end, which is set on the first statement (on which
  /// [except] is called). Also, the [other] statement must not contain
  /// compound parts on its own.
  SelectStatement except(BaseSelectStatement other) {
    return _asSelectStatement().._addCompound(CompoundOperator.except, other);
  }

  /// Appends the [other] statement as a `INTERSECT` clause after this query.
  ///
  /// The database will run both queries and return all rows that were returned
  /// by both queries. For this to work, this and [other] must have compatible
  /// columns.
  ///
  /// The [other] query must not include a `LIMIT` or a `ORDER BY` clause.
  /// Compound statements can only contain a single `LIMIT` and `ORDER BY`
  /// clause at the end, which is set on the first statement (on which
  /// [intersect] is called). Also, the [other] statement must not contain
  /// compound parts on its own.
  SelectStatement intersect(BaseSelectStatement other) {
    return _asSelectStatement()
      .._addCompound(CompoundOperator.intersect, other);
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addSelectStatement(this);
  }

  Self _asSelf();

  SelectStatement _withAddedJoin(Join join) {
    return _asSelectStatement().._addJoin(join);
  }

  SelectStatement _asSelectStatement();

  /// Creates a function that, given a [DriftRow], extracts the result set for
  /// this [BaseSelectStatement].
  @internal
  Row Function(DriftRow) createMapper(ResultSetStructure structure);

  List<Row> _mapResults(QueryResult result) {
    final resultSet = DriftResultSet(
      structure,
      result.resultSet!,
      _database.dialect,
    );
    final converter = createMapper(structure);
    return resultSet.map(converter).toList();
  }

  @override
  Future<List<Row>> get() async {
    final session = await _database.currentSession();
    final query = _database.dialect.compile(this);
    final results = await session.execute(query);
    return _mapResults(results);
  }

  @override
  Stream<List<Row>> watch() {
    final stmt = _database.dialect.compile(this);

    final streams = _database.currentStreamQueryStore();
    final raw = streams.registerStream<QueryResult>(
      QueryStreamFetcher(
        readsFrom: TableUpdateQuery.allOf([
          for (final watched in stmt.watchedTables)
            TableUpdateQuery.onTableName(watched),
        ]),
        key: StreamKey(stmt.sql, stmt.variables),
        fetchData: () async {
          final currentSession = await _database.currentSession();
          return currentSession.execute(stmt);
        },
        prepare: () => _database.currentSession(),
      ),
    );
    return raw.map(_mapResults);
  }
}

/// A select statement referencing multiple tables.
final class SelectStatement
    extends BaseSelectStatement<SelectStatement, DriftRow> {
  final bool _includeJoinsByDefault;

  /// @nodoc
  SelectStatement(
    super.database, {

    /// Whether tables joined to this statement should have their columns added
    /// by default.
    ///
    /// It may make sense not to add those columns in case the join is only
    /// referenced in a `WHERE` clause.
    bool includeJoinsByDefault = true,
    super.distinct,
  }) : _includeJoinsByDefault = includeJoinsByDefault;

  void _applyFrom(SingleTableSelectStatement other) {
    addResultSet(other.resultSet);

    assert(distinct == other.distinct);
    from.addAll(other.from);
    whereClause = other.whereClause;
    groupByClause = other.groupByClause;
    orderByClause = other.orderByClause;
    limitClause = other.limitClause;
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
  SelectStatement where(Expression<bool> predicate) {
    if (whereClause == null) {
      whereClause = WhereClause(predicate);
    } else {
      whereClause = WhereClause(whereClause!.condition & predicate);
    }

    return this;
  }

  /// Orders the results of this statement by the ordering [terms].
  SelectStatement orderBy(List<OrderingTerm> terms) {
    orderByClause = OrderBy(terms);
    return this;
  }

  @override
  SelectStatement _asSelf() => this;

  @override
  SelectStatement _asSelectStatement() => this;

  void _addJoin(Join join) {
    from.add(join);
    if (join.includeInResult ?? _includeJoinsByDefault) {
      addResultSet(join.table.resultSet);
    }
  }

  void _addCompound(CompoundOperator operator, BaseSelectStatement other) {
    if (other.limitClause != null ||
        other.orderByClause != null ||
        other.compounds.isNotEmpty) {
      throw ArgumentError(
        "Can't add compound query that has a limit or an order-by clause. "
        'Also, the added query must hot have its own compound parts. Add  '
        'the clauses and parts to the top-level parts instead.',
      );
    }

    final normalizedOther = other._asSelectStatement();
    final dialect = _database.dialect;

    var columnsHere = structure.expressions.keys.iterator;
    var otherColumns = other.structure.expressions.keys.iterator;
    var columnCount = 0;

    while (columnsHere.moveNext()) {
      if (!otherColumns.moveNext()) {
        throw ArgumentError(
          "Can't add select with fewer columns (added part has "
          '$columnCount columns, the original source has more).',
        );
      }

      var here = columnsHere.current;
      var otherColumn = otherColumns.current;

      if (here.resolveType(dialect) != otherColumn.resolveType(dialect)) {
        throw ArgumentError(
          "Can't add part because the column types at index $columnCount "
          'differ.',
        );
      }

      columnCount++;
    }

    if (otherColumns.moveNext()) {
      throw ArgumentError(
        "Can't add select with more columns (the original query has "
        '$columnCount columns, the added part has more).',
      );
    }

    compounds.add(CompoundSelect._(operator, normalizedOther));
  }

  @override
  DriftRow Function(DriftRow) createMapper(ResultSetStructure resultSet) {
    return (row) => row;
  }
}

/// Signature of a function that generates an [OrderingTerm] when provided with
/// a table.
typedef OrderClauseGenerator<T> = OrderingTerm Function(T tbl);

/// A select statement selecting from a single table.
///
/// Because only a single table is in scope, some helper methods are available
/// through [SingleTableStatementMixin].
final class SingleTableSelectStatement<
  Row extends Object,
  RS extends ResultSet<Row, RS>
>
    extends BaseSelectStatement<SingleTableSelectStatement<Row, RS>, Row>
    with
        SingleTableStatementMixin<
          Row,
          RS,
          SingleTableSelectStatement<Row, RS>
        > {
  @override
  final ResultSet<Row, RS> resultSet;

  /// @nodoc
  SingleTableSelectStatement(
    super._database,
    this.resultSet, {
    super.distinct,
  }) {
    structure.addSelectStarFromSingleTable(resultSet);
    from.add(FromResultSet(resultSet));
  }

  /// Orders the result by the given clauses. The clauses coming first in the
  /// list have a higher priority, the later clauses are only considered if the
  /// first clause considers two rows to be equal.
  ///
  /// Example that first displays the users who are awesome and sorts users by
  /// their id as a secondary criterion:
  /// ```
  /// (db.select(db.users)
  ///    ..orderBy([
  ///      (u) =>
  ///        OrderingTerm(expression: u.isAwesome, mode: OrderingMode.desc),
  ///      (u) => OrderingTerm(expression: u.id)
  ///    ]))
  ///  .get()
  /// ```
  SingleTableSelectStatement<Row, RS> orderBy(
    List<OrderClauseGenerator<RS>> clauses,
  ) {
    orderByClause = OrderBy(
      clauses.map((t) => t(resultSet.asSelfType())).toList(),
    );
    return this;
  }

  @override
  SingleTableSelectStatement<Row, RS> asSelf() => this;

  @override
  SingleTableSelectStatement<Row, RS> _asSelf() => this;

  @override
  Row Function(DriftRow p1) createMapper(ResultSetStructure resultSet) {
    final inner = this.resultSet.createMapperToDart(resultSet);
    return (row) => inner(row)!;
  }

  @override
  SelectStatement _asSelectStatement() {
    return SelectStatement(_database, distinct: distinct).._applyFrom(this);
  }
}

/// A source for from clauses
sealed class FromClauseElement implements SqlComponent {}

/// An operator used to compose joins, see [Join].
enum JoinOperator implements SqlComponent {
  /// Perform an `INNER` join.
  inner('INNER JOIN'),

  /// Perform a `LEFT OUTER` join.
  leftOuter('LEFT OUTER JOIN'),

  /// Perform a `RIGHT OUTER` join.
  rightOuter('RIGHT OUTER JOIN'),

  /// Perform a `FULL OUTER` join.
  fullOuter('FULL OUTER JOIN'),

  /// Perform a `CROSS` join.
  cross('CROSS JOIN');

  /// The default lexeme to generate for this join operator. Some SQL dialects
  /// may choose to override this.
  final String defaultLexeme;

  const JoinOperator(this.defaultLexeme);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addJoinOperator(this);
  }
}

/// Represents a join of a [table] to a query.
///
/// This allows applying a [JoinOperator] and optionally also an [on] condition.
final class Join extends FromClauseElement {
  /// The [JoinOperator] to use for this join.
  final JoinOperator operator;

  /// The [ResultSet] that will be added to the query.
  final FromResultSet table;

  /// For joins that aren't [JoinOperator.cross], contains an additional predicate
  /// that must be matched for the join.
  final Expression<bool>? on;

  /// Whether [table] should appear in the result set (defaults to true).
  /// Default value can be changed by `includeJoinedTableColumns` in
  /// `selectOnly` statements.
  ///
  /// It can be useful to exclude some tables. Sometimes, tables are used in a
  /// join only to run aggregate functions on them.
  final bool? includeInResult;

  /// Create a join clause with the given [operator] and [table].
  Join(this.operator, ResultSetDsl table, {this.on, this.includeInResult})
    : table = FromResultSet(ResultSet.fromDsl(table));

  /// Create an `INNER JOIN` for the [table].
  Join.inner(ResultSetDsl table, {this.on, this.includeInResult})
    : operator = JoinOperator.inner,
      table = FromResultSet(ResultSet.fromDsl(table));

  /// Create an `LEFT OUTER JOIN` for the [table].
  Join.leftOuter(ResultSetDsl table, {this.on, this.includeInResult})
    : operator = JoinOperator.leftOuter,
      table = FromResultSet(ResultSet.fromDsl(table));

  /// Create a `CROSS JOIN` for the [table].
  Join.cross(ResultSetDsl table, {this.on, this.includeInResult})
    : operator = JoinOperator.cross,
      table = FromResultSet(ResultSet.fromDsl(table));

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addJoin(this);
  }
}

/// Select from a generated table or view.
final class FromResultSet extends FromClauseElement {
  /// The result set to select from.
  final ResultSet resultSet;

  /// @nodoc
  FromResultSet(this.resultSet);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addFromResultSet(this);
  }
}

/// A set operator used to combine the results of multiple select statement into
/// one.
enum CompoundOperator implements SqlComponent {
  /// A `UNION` operator, returning rows from both select statements (removing
  /// duplicates).
  union('UNION'),

  /// A `UNION ALL` operator, returning rows from both select statements without
  /// filtering duplicates.
  unionAll('UNION ALL'),

  /// An `INTERSECT` operator, returning only rows that are present in both
  /// select statements.
  intersect('INTERSECT'),

  /// An `EXCEPT` operator, returning rows that are present in the first select
  /// statement but not the second.
  except('EXCEPT');

  /// The lexeme this operator has on most SQL dialects.
  final String defaultLexeme;

  const CompoundOperator(this.defaultLexeme);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addCompoundOperator(this);
  }
}

/// A select statement that has been added to an existing [SelectStatement] by
/// using a [CompoundOperator].
final class CompoundSelect implements SqlComponent {
  /// The operator (e.g. `UNION`) to use for the [statement].
  final CompoundOperator operator;

  /// The statement being added to a compound select.
  final SelectStatement statement;

  CompoundSelect._(this.operator, this.statement);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addCompoundSelect(this);
  }
}
