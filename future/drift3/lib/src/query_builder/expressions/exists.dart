import '../compiler.dart';
import '../statements/select.dart';
import 'expression.dart';

/// The `EXISTS` operator checks whether the [select] subquery returns any rows.
Expression<bool> existsQuery(BaseSelectStatement select) {
  return ExistsExpression(select, not: false);
}

/// The `NOT EXISTS` operator evaluates to `true` if the [select] subquery does
/// not return any rows.
Expression<bool> notExistsQuery(BaseSelectStatement select) {
  return ExistsExpression(select, not: true);
}

/// An `EXISTS` (or `NOT EXISTS`) expression in SQL.
///
/// This expression evaluates the [select] statement and reports whether that
/// statement would return any rows.
final class ExistsExpression extends Expression<bool> {
  /// The inner select statement to run.
  ///
  /// This expression evaluates to true iff [select] returns any rows.
  final BaseSelectStatement select;

  /// Whether this should be a `NOT EXISTS` expression instead.
  final bool not;

  /// Creates an [ExistsExpression] from the inner [select] statement.
  ExistsExpression(this.select, {this.not = false});

  @override
  Precedence get precedence => Precedence.comparisonEq;

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addExistsExpression(this);
  }

  @override
  int get hashCode => Object.hash(select, not);

  @override
  bool operator ==(Object other) {
    return other is ExistsExpression &&
        other.not == not &&
        other.select == select;
  }
}
