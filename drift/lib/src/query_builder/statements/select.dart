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

sealed class BaseSelectStatement<Self extends BaseSelectStatement<Self, Row>,
    Row> extends SqlStatement with Selectable<Row> {
  final ResultSetStructure structure = ResultSetStructure();

  final bool distinct;
  final List<FromClauseElement> from = [];

  WhereClause? whereClause;

  /// The optional `GROUP BY` clause for this select statement.
  GroupBy? groupByClause;

  /// The optional `ORDER BY` clause for this select statement.
  OrderBy? orderByClause;

  /// The optional `LIMIT` clause restricting the amount of rows returned by
  /// this statement.
  Limit? limitClause;

  /// The database this statement should be sent to.
  DatabaseConnectionUser _database;

  BaseSelectStatement(this._database, {this.distinct = false});

  ColumnPosition get _nextPosition {
    final index = structure.expressions.length;
    return (name: 'c$index', index: index);
  }

  Self addColumn(Expression expression) {
    structure.expressions[expression] ??= _nextPosition;
    return _asSelf();
  }

  Self addColumns(Iterable<Expression> expressions) {
    for (final expression in expressions) {
      structure.expressions[expression] ??= _nextPosition;
    }
    return _asSelf();
  }

  @internal
  void addResultSet(ResultSet resultSet) {
    if (structure.tables.containsKey(resultSet)) {
      throw StateError(
          'Result set $resultSet has been added to select multiple times, please use an alias');
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

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addSelectStatement(this);
  }

  Self _asSelf();

  SelectStatement _withAddedJoin(Join join);

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

  SelectStatement(super.database,
      {bool includeJoinsByDefault = true, super.distinct})
      : _includeJoinsByDefault = includeJoinsByDefault;

  void _applyFrom(SingleTableSelectStatement other) {
    addResultSet(other.resultSet);

    assert(distinct == other.distinct);
    from.addAll(other.from);
    whereClause = other.whereClause;
    groupByClause = other.groupByClause;
    orderByClause = other.orderByClause;
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
    if (whereClause == null) {
      whereClause = WhereClause(predicate);
    } else {
      whereClause = WhereClause(whereClause!.condition & predicate);
    }
  }

  /// Orders the results of this statement by the ordering [terms].
  void orderBy(List<OrderingTerm> terms) {
    orderByClause = OrderBy(terms);
  }

  @override
  SelectStatement _asSelf() => this;

  @override
  SelectStatement _withAddedJoin(Join join) {
    from.add(join);
    if (join.includeInResult ?? _includeJoinsByDefault) {
      addResultSet(join.table.resultSet);
    }
    return this;
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
  final ResultSet<Row, RS> resultSet;

  SingleTableSelectStatement(super._database, this.resultSet,
      {super.distinct}) {
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
      List<OrderClauseGenerator<RS>> clauses) {
    orderByClause =
        OrderBy(clauses.map((t) => t(resultSet.asSelfType())).toList());
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
  SelectStatement _withAddedJoin(Join join) {
    return SelectStatement(_database, distinct: distinct)
      .._applyFrom(this)
      .._withAddedJoin(join);
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

final class FromResultSet extends FromClauseElement {
  final ResultSet resultSet;

  FromResultSet(this.resultSet);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addFromResultSet(this);
  }
}
