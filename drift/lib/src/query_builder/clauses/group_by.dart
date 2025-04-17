import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import '../compiler.dart';
import '../expressions/expression.dart';

/// A `GROUP BY` clause in SQL.
@immutable
final class GroupBy implements SqlComponent {
  /// The expressions to group by.
  final BuiltList<Expression> groupBy;

  /// Optional, a having clause to exclude some groups.
  final Expression<bool>? having;

  /// Creates a `GROUP BY` clause by the expressions to use as group keys
  /// ([groupBy]) and an optional [having] clause.
  GroupBy(Iterable<Expression> groupBy, {this.having})
      : groupBy = BuiltList.of(groupBy);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addGroupBy(this);
  }
}
