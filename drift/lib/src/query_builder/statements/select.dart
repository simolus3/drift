import 'package:meta/meta.dart';

import '../../connections/connection.dart';
import '../../connections/result_set.dart';
import '../../dsl/table.dart';
import '../../runtime/database/connection_user.dart';
import '../../runtime/selectable.dart';
import '../clauses/where.dart';
import '../compiler.dart';
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

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addSelectStatement(this);
  }

  Self _asSelf();

  SelectStatement _withAddedJoin(Join join);

  Row Function(DriftRow) _createMapper(DriftResultSet resultSet);

  @override
  Future<List<Row>> get() async {
    final session = await _database.currentSession();
    final query = StatementInfo(_database.dialect.compile(this));
    final results = await session.execute(query);
    final resultSet =
        DriftResultSet(structure, results.resultSet!, _database.dialect);

    final converter = _createMapper(resultSet);
    return resultSet.map(converter).toList();
  }

  @override
  Stream<List<Row>> watch() {
    // TODO: implement watch
    throw UnimplementedError();
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
  }

  @override
  SelectStatement _asSelf() => this;

  @override
  SelectStatement _withAddedJoin(Join join) {
    from.add(join);
    if (join.includeInResult ?? _includeJoinsByDefault) {
      addResultSet(join.table);
    }
    return this;
  }

  @override
  DriftRow Function(DriftRow) _createMapper(DriftResultSet resultSet) {
    return (row) => row;
  }
}

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
    final positions = <ColumnPosition>[];
    for (final (i, column) in resultSet.columns.indexed) {
      final position = (name: column.name, index: i);
      structure.expressions[column] = position;
      positions.add(position);
    }

    structure.tables[resultSet] = positions;
    from.add(TableReference(resultSet));
  }

  @override
  SingleTableSelectStatement<Row, RS> asSelf() => this;

  @override
  SingleTableSelectStatement<Row, RS> _asSelf() => this;

  @override
  Row Function(DriftRow p1) _createMapper(DriftResultSet resultSet) {
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
  inner('INNER'),
  leftOuter('LEFT OUTER'),
  cross('CROSS');

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
  final ResultSet table;

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
      : table = ResultSet.fromDsl(table);

  /// Create an `INNER JOIN` for the [table].
  Join.inner(ResultSetDsl table, {this.on, this.includeInResult})
      : operator = JoinOperator.inner,
        table = ResultSet.fromDsl(table);

  /// Create an `LEFT OUTER JOIN` for the [table].
  Join.leftOuter(ResultSetDsl table, {this.on, this.includeInResult})
      : operator = JoinOperator.leftOuter,
        table = ResultSet.fromDsl(table);

  /// Create a `CROSS JOIN` for the [table].
  Join.cross(ResultSetDsl table, {this.on, this.includeInResult})
      : operator = JoinOperator.cross,
        table = ResultSet.fromDsl(table);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addJoin(this);
  }
}

final class TableReference extends FromClauseElement {
  final ResultSet resultSet;

  TableReference(this.resultSet);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addTableReference(this);
  }
}
