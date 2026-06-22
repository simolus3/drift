import '../../dsl/table.dart';
import '../../query_builder/expressions/expression.dart';
import '../../query_builder/schema/result_set.dart';
import '../compiler.dart';

/// A `FROM` clause providing the tables in SQL.
final class FromClause implements SqlComponent {
  /// List of all [FromClauseElement] added to this `FROM` clause.
  final List<FromClauseElement> elements = [];

  /// Adds a join to this `FROM` clause.
  void addJoin(Join join) {
    elements.add(join);
  }

  /// Adds multiple joins to this `FROM` clause.
  void addJoins(Iterable<Join> joins) {
    elements.addAll(joins);
  }

  /// Adds a result set to this `FROM` clause.
  void addResultSet(ResultSet resultSet) {
    elements.add(FromResultSet(resultSet));
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addFromClause(this);
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

  /// Create an `RIGHT OUTER JOIN` for the [table].
  Join.rightOuter(ResultSetDsl table, {this.on, this.includeInResult})
    : operator = JoinOperator.rightOuter,
      table = FromResultSet(ResultSet.fromDsl(table));

  /// Create an `FULL OUTER JOIN` for the [table].
  Join.fullOuter(ResultSetDsl table, {this.on, this.includeInResult})
    : operator = JoinOperator.fullOuter,
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
