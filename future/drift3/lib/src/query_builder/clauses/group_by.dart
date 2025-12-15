import '../compiler.dart';
import '../expressions/expression.dart';

/// A `GROUP BY` clause in SQL.
final class GroupBy implements SqlComponent {
  /// The expressions to group by.
  final List<Expression> groupBy;

  /// Optional, a having clause to exclude some groups.
  final Expression<bool>? having;

  /// Creates a `GROUP BY` clause by the expressions to use as group keys
  /// ([groupBy]) and an optional [having] clause.
  GroupBy(this.groupBy, {this.having});

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addGroupBy(this);
  }
}
