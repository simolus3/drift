import '../compiler.dart';
import '../statements/select.dart';
import 'expression.dart';

/// Creates a subquery expression from the given [statement].
///
/// The statement, which can be created via [DatabaseConnectionUser.select] in
/// a database class, must return exactly one row with exactly one column.
Expression<R> subqueryExpression<R extends Object>(
  BaseSelectStatement statement,
) {
  return SubqueryExpression<R>(statement);
}

/// An expression evaluating to the single row and single column of an inner
/// select [statement].
final class SubqueryExpression<R extends Object> extends Expression<R> {
  /// The inner select statement to evaluate.
  final BaseSelectStatement statement;

  /// @nodoc
  SubqueryExpression(this.statement);

  @override
  int get hashCode => statement.hashCode;

  @override
  bool operator ==(Object other) {
    return other is SubqueryExpression && other.statement == statement;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addSubqueryExpression(this);
  }
}
