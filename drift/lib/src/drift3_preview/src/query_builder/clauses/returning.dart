import '../../connection/result_set.dart';
import '../../database/connection_user.dart';
import '../compiler.dart';
import '../expressions/expression.dart';
import '../results.dart';
import '../schema/result_set.dart';
import '../schema/table.dart';
import '../statements/statement.dart';

/// A statement with an optional [ReturningClause].
abstract base class StatementWithReturningClause<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>
>
    extends SqlStatement {
  /// The primary table affected by this statement.
  final GeneratedTable<Row, RS> table;

  /// An optional `RETURNING` clause part of this statement.
  ReturningClause? returning;

  /// @nodoc
  StatementWithReturningClause(this.table);

  /// Adds a `RETURNING *` clause to this insert statement.
  void returningAll() {
    returning = ReturningClause()..structure.addResultSet(table);
  }

  /// Adds a `RETURNING` clause returning the given [expressions] which are
  /// evaluated against each row affected by this statement.
  void returningOnly(List<Expression> expressions) {
    returning = ReturningClause()..structure.addColumns(expressions);
  }
}

/// A `RETURNING *` clause that can appear as part of an `INSERT`, `UPDATE` or
/// `DELETE` statement.
final class ReturningClause implements SqlComponent {
  /// The generated [ResultSetStructure] representing columns for this
  /// `RETURNING` clause.
  final ResultSetStructure structure = ResultSetStructure();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addReturningClause(this);
  }

  /// Maps rows from the given [result] using the result set for this
  /// `RETURNING` clause.
  ///
  /// [resultSet] must to be added to [structure] before calling this method
  List<Row>
  interpretResults<Row extends Object, RS extends GeneratedTable<Row, RS>>(
    DatabaseConnectionUser database,
    QueryResult result,
    ResultSet<Row, RS> resultSet,
  ) {
    final mapper = resultSet.createMapperToDart(database.dialect, structure);

    return [for (final row in result.resultSet!) mapper(row)!];
  }

  /// Maps rows from the given [result] using the expression for this
  /// `RETURNING` clause.
  ///
  /// expressions must to be added to [structure] before calling this method
  List<DriftRow> interpretExpressionResults(
    DatabaseConnectionUser database,
    QueryResult result,
  ) {
    final mapper = structure.createMapperToDriftRow(database.dialect);

    return [for (final row in result.resultSet!) mapper(row)];
  }
}
