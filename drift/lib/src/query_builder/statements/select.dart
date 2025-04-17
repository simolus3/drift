import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import '../../connections/connection.dart';
import '../../connections/result_set.dart';
import '../../dsl/table.dart';
import '../../runtime/database/connection_user.dart';
import '../../runtime/selectable.dart';
import '../../runtime/streams/store.dart';
import '../../runtime/streams/update_rules.dart';
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

@immutable
sealed class BaseSelectStatement<Self extends BaseSelectStatement<Self, Row>,
    Row> extends SqlStatement with Selectable<Row> {
  final ResultSetStructure structure;

  final bool distinct;
  final BuiltList<FromClauseElement> from;

  final WhereClause? whereClause;

  /// The optional `GROUP BY` clause for this select statement.
  final GroupBy? groupByClause;

  /// The optional `ORDER BY` clause for this select statement.
  final OrderBy? orderByClause;

  /// The optional `LIMIT` clause restricting the amount of rows returned by
  /// this statement.
  final Limit? limitClause;

  /// All [CompoundSelect] statements that have been added to this select
  /// statement using [union], [unionAll], [except] and [intersect].
  final BuiltList<CompoundSelect> compounds;

  /// The database this statement should be sent to.
  final DatabaseConnectionUser _database;

  BaseSelectStatement(this._database, {this.distinct = false})
      : compounds = BuiltList(),
        from = BuiltList(),
        whereClause = null,
        groupByClause = null,
        orderByClause = null,
        structure = ResultSetStructure(),
        limitClause = null;

  BaseSelectStatement._(
    this._database, {
    required this.distinct,
    required this.whereClause,
    required this.groupByClause,
    required this.orderByClause,
    required this.limitClause,
    required this.structure,
    required this.from,
    required this.compounds,
  });

  Self _copyWith({
    // ignore: unused_element_parameter
    bool? distinct,
    // ignore: unused_element_parameter
    BuiltList<FromClauseElement>? from,
    // ignore: unused_element_parameter
    WhereClause? whereClause,
    GroupBy? groupByClause,
    // ignore: unused_element_parameter
    OrderBy? orderByClause,
    Limit? limitClause,
    ResultSetStructure? structure,
    // ignore: unused_element_parameter
    BuiltList<CompoundSelect>? compounds,
  });

  ColumnPosition get _nextPosition {
    final index = structure.expressions.length;
    return (name: 'c$index', index: index);
  }

  SelectStatement addColumn(Expression expression) {
    final expressionsBuilder = structure.expressions.toBuilder();
    expressionsBuilder[expression] ??= _nextPosition;
    return _copyWith(
        structure: structure.copyWith(
      expressions: expressionsBuilder.build(),
    ))._asSelectStatement();
  }

  SelectStatement addColumns(Iterable<Expression> expressions) {
    final expressionsBuilder = structure.expressions.toBuilder();

    for (final expression in expressions) {
      expressionsBuilder[expression] ??= _nextPosition;
    }
    return _copyWith(
        structure: structure.copyWith(
      expressions: expressionsBuilder.build(),
    ))._asSelectStatement();
  }

  @internal
  Self withResultSet(ResultSet resultSet) {
    Self stmt = this._asSelf();
    if (stmt.structure.tables.containsKey(resultSet)) {
      throw StateError(
          'Result set $resultSet has been added to select multiple times, please use an alias');
    }

    final expressionsBuilder = stmt.structure.expressions.toBuilder();
    final tablesBuilder = stmt.structure.tables.toBuilder();

    final positions = <ColumnPosition>[];
    for (final column in resultSet.columns) {
      final columnPosition = _nextPosition;
      positions.add(columnPosition);
      expressionsBuilder[column] = columnPosition;
    }
    tablesBuilder[resultSet] = positions.build();
    stmt = stmt._copyWith(
        structure: stmt.structure.copyWith(
            expressions: expressionsBuilder.build(),
            tables: tablesBuilder.build()));
    return stmt;
  }

  @internal
  Self withAddedFrom(FromClauseElement fromClause) {
    return _copyWith(from: (from.toBuilder()..add(fromClause)).build());
  }

  /// Adds [table] to this query using an `INNER JOIN` operator.
  SelectStatement innerJoin(ResultSetDsl table,
      {Expression<bool>? on, bool? includeInResult}) {
    return _withAddedJoin(
        Join.inner(table, on: on, includeInResult: includeInResult));
  }

  /// Adds [table] to this query using a `LEFT OUTER JOIN` operator.
  SelectStatement leftOuter(ResultSetDsl table,
      {Expression<bool>? on, bool? includeInResult}) {
    return _withAddedJoin(
        Join.leftOuter(table, on: on, includeInResult: includeInResult));
  }

  /// Adds [table] to this query using a `CROSS JOIN` operator.
  SelectStatement cross(ResultSetDsl table, {bool? includeInResult}) {
    return _withAddedJoin(Join.cross(table, includeInResult: includeInResult));
  }

  /// Groups the result by values in [expressions].
  ///
  /// An optional [having] attribute can be set to exclude certain groups.
  Self groupBy(Iterable<Expression> expressions, {Expression<bool>? having}) {
    return _copyWith(
        groupByClause: GroupBy(expressions.toList(), having: having));
  }

  /// Limits the amount of rows returned by capping them at [limit]. If [offset]
  /// is provided as well, the first [offset] rows will be skipped and not
  /// included in the result.
  Self limit(int limit, {int? offset}) {
    return _copyWith(limitClause: Limit(limit, offset));
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
    return _asSelectStatement()._withCompound(CompoundOperator.union, other);
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
    return _asSelectStatement()._withCompound(CompoundOperator.unionAll, other);
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
    return _asSelectStatement()._withCompound(CompoundOperator.except, other);
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
        ._withCompound(CompoundOperator.intersect, other);
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addSelectStatement(this);
  }

  Self _asSelf();

  SelectStatement _withAddedJoin(Join join) {
    return _asSelectStatement()._withJoin(join);
  }

  SelectStatement _asSelectStatement();

  /// Creates a function that, given a [DriftRow], extracts the result set for
  /// this [BaseSelectStatement].
  @internal
  Row Function(DriftRow) createMapper(ResultSetStructure structure);

  List<Row> _mapResults(QueryResult result) {
    final resultSet =
        DriftResultSet(structure, result.resultSet!, _database.dialect);
    final converter = createMapper(structure);
    return resultSet.map(converter).toList();
  }

  @override
  Future<List<Row>> get() async {
    final session = await _database.currentSession();
    final query = StatementInfo(_database.dialect.compile(this));
    final results = await session.execute(query);
    return _mapResults(results);
  }

  @override
  Stream<List<Row>> watch() {
    final stmt = _database.dialect.compile(this);

    final streams = _database.currentStreamQueryStore();
    final raw = streams.registerStream<QueryResult>(
      QueryStreamFetcher(
        readsFrom: TableUpdateQuery.onAllTables(stmt.watchedTables),
        key: StreamKey(stmt.sql, stmt.variables),
        fetchData: () async {
          final currentSession = await _database.currentSession();
          return currentSession.execute(StatementInfo(stmt));
        },
      ),
      _database,
    );
    return raw.map(_mapResults);
  }
}

final class SelectStatement
    extends BaseSelectStatement<SelectStatement, DriftRow> {
  final bool _includeJoinsByDefault;

  @override
  final BuiltMap<Symbol, Object?> dialectSpecificOptions = BuiltMap();

  SelectStatement(super.database,
      {bool includeJoinsByDefault = true, super.distinct})
      : _includeJoinsByDefault = includeJoinsByDefault;

  SelectStatement._(super.database,
      {required bool includeJoinsByDefault,
      required super.distinct,
      required super.whereClause,
      required super.groupByClause,
      required super.orderByClause,
      required super.from,
      required super.compounds,
      required super.structure,
      required super.limitClause})
      : _includeJoinsByDefault = includeJoinsByDefault,
        super._();

  @override
  SelectStatement _copyWith(
      {bool? distinct,
      BuiltList<FromClauseElement>? from,
      WhereClause? whereClause,
      GroupBy? groupByClause,
      OrderBy? orderByClause,
      Limit? limitClause,
      ResultSetStructure? structure,
      bool? includeJoinsByDefault,
      BuiltList<CompoundSelect>? compounds}) {
    return SelectStatement._(
      _database,
      includeJoinsByDefault: includeJoinsByDefault ?? _includeJoinsByDefault,
      distinct: distinct ?? this.distinct,
      from: from ?? this.from,
      whereClause: whereClause ?? this.whereClause,
      groupByClause: groupByClause ?? this.groupByClause,
      orderByClause: orderByClause ?? this.orderByClause,
      limitClause: limitClause ?? this.limitClause,
      compounds: compounds ?? this.compounds,
      structure: structure ?? this.structure,
    );
  }

  SelectStatement _applyFrom(SingleTableSelectStatement other) {
    var stmt = withResultSet(other.resultSet);

    assert(distinct == other.distinct);
    stmt = stmt._copyWith(
      from: (from.toBuilder()..addAll(other.from)).build(),
      whereClause: other.whereClause,
      groupByClause: other.groupByClause,
      orderByClause: other.orderByClause,
      limitClause: other.limitClause,
    );
    return stmt;
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
      return _copyWith(whereClause: WhereClause(predicate));
    } else {
      return _copyWith(
          whereClause: WhereClause(whereClause!.condition & predicate));
    }
  }

  /// Orders the results of this statement by the ordering [terms].
  SelectStatement orderBy(List<OrderingTerm> terms) {
    return _copyWith(orderByClause: OrderBy(terms));
  }

  @override
  SelectStatement _asSelf() => this;

  @override
  SelectStatement _asSelectStatement() => this;

  SelectStatement _withJoin(Join join) {
    var stmt = _copyWith(from: (from.toBuilder()..add(join)).build());
    if (join.includeInResult ?? _includeJoinsByDefault) {
      stmt = stmt.withResultSet(join.table.resultSet);
    }
    return stmt;
  }

  SelectStatement _withCompound(
          CompoundOperator operator, BaseSelectStatement other) =>
      __withCompound(
        this,
        _database,
        operator,
        other,
      );

  static SelectStatement __withCompound(
      SelectStatement stmt,
      DatabaseConnectionUser database,
      CompoundOperator operator,
      BaseSelectStatement other) {
    if (other.limitClause != null ||
        other.orderByClause != null ||
        other.compounds.isNotEmpty) {
      throw ArgumentError(
          "Can't add compound query that has a limit or an order-by clause. "
          'Also, the added query must hot have its own compound parts. Add  '
          'the clauses and parts to the top-level parts instead.');
    }

    final normalizedOther = other._asSelectStatement();
    final dialect = database.dialect;

    var columnsHere = stmt.structure.expressions.keys.iterator;
    var otherColumns = other.structure.expressions.keys.iterator;
    var columnCount = 0;

    while (columnsHere.moveNext()) {
      if (!otherColumns.moveNext()) {
        throw ArgumentError(
            "Can't add select with fewer columns (added part has "
            '$columnCount columns, the original source has more).');
      }

      var here = columnsHere.current;
      var otherColumn = otherColumns.current;

      if (here.resolveType(dialect) != otherColumn.resolveType(dialect)) {
        throw ArgumentError(
            "Can't add part because the column types at index $columnCount "
            'differ.');
      }

      columnCount++;
    }

    if (otherColumns.moveNext()) {
      throw ArgumentError(
          "Can't add select with more columns (the original query has "
          '$columnCount columns, the added part has more).');
    }
    return stmt._copyWith(
        compounds: (stmt.compounds.toBuilder()
              ..add(CompoundSelect._(operator, normalizedOther)))
            .build());
  }

  @override
  DriftRow Function(DriftRow) createMapper(ResultSetStructure resultSet) {
    return (row) => row;
  }
}

/// Signature of a function that generates an [OrderingTerm] when provided with
/// a table.
typedef OrderClauseGenerator<T> = OrderingTerm Function(T tbl);

final class SingleTableSelectStatement<Row extends Object,
        RS extends ResultSet<Row, RS>>
    extends BaseSelectStatement<SingleTableSelectStatement<Row, RS>, Row>
    with
        SingleTableStatementMixin<Row, RS,
            SingleTableSelectStatement<Row, RS>> {
  @override
  final BuiltMap<Symbol, Object?> dialectSpecificOptions = BuiltMap();
  @override
  final ResultSet<Row, RS> resultSet;

  factory SingleTableSelectStatement(
      DatabaseConnectionUser database, ResultSet<Row, RS> resultSet,
      {bool distinct = false}) {
    final structure =
        ResultSetStructure().withSelectStarFromSingleTable(resultSet);
    final from = BuiltList<FromResultSet>([FromResultSet(resultSet)]);
    return SingleTableSelectStatement<Row, RS>._(
      database,
      resultSet: resultSet,
      distinct: distinct,
      from: from,
      whereClause: null,
      groupByClause: null,
      orderByClause: null,
      limitClause: null,
      compounds: BuiltList<CompoundSelect>(),
      structure: structure,
    );
  }

  SingleTableSelectStatement._(super.database,
      {required super.distinct,
      required super.whereClause,
      required super.groupByClause,
      required super.orderByClause,
      required super.from,
      required super.compounds,
      required super.structure,
      required this.resultSet,
      required super.limitClause})
      : super._();

  @override
  SingleTableSelectStatement<Row, RS> _copyWith(
      {bool? distinct,
      BuiltList<FromClauseElement>? from,
      WhereClause? whereClause,
      GroupBy? groupByClause,
      OrderBy? orderByClause,
      Limit? limitClause,
      ResultSet<Row, RS>? resultSet,
      ResultSetStructure? structure,
      BuiltList<CompoundSelect>? compounds}) {
    return SingleTableSelectStatement._(
      _database,
      resultSet: resultSet ?? this.resultSet,
      distinct: distinct ?? this.distinct,
      from: from ?? this.from,
      whereClause: whereClause ?? this.whereClause,
      groupByClause: groupByClause ?? this.groupByClause,
      orderByClause: orderByClause ?? this.orderByClause,
      limitClause: limitClause ?? this.limitClause,
      compounds: compounds ?? this.compounds,
      structure: structure ?? this.structure,
    );
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
      List<OrderClauseGenerator<RS>> clauses) {
    return _copyWith(
        orderByClause: OrderBy(
      clauses.map((t) => t(resultSet.asSelfType())).toList(),
    ));
  }

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

  @override
  SingleTableSelectStatement<Row, RS> withWhereClause(WhereClause whereClause) {
    return _copyWith(whereClause: whereClause);
  }
}

sealed class FromClauseElement implements SqlComponent {}

/// An operator used to compose joins, see [Join].
enum JoinOperator implements SqlComponent {
  /// Perform an inner join,
  inner('INNER JOIN'),
  leftOuter('LEFT OUTER JOIN'),
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
@immutable
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

@immutable
final class FromResultSet extends FromClauseElement {
  final ResultSet resultSet;

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
@immutable
final class CompoundSelect implements SqlComponent {
  final CompoundOperator operator;
  final SelectStatement statement;

  CompoundSelect._(this.operator, this.statement);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addCompoundSelect(this);
  }
}
