import '../compiler.dart';
import '../expressions/expression.dart';

/// A `WHERE` clause acting as a filter in SQL.
final class WhereClause implements SqlComponent {
  /// The condition for this `WHERE` clause.
  final Expression<bool> condition;

  /// Creates a `WHERE` clause in SQL from the underlying [condition].
  WhereClause(this.condition);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addWhereClause(this);
  }
}
