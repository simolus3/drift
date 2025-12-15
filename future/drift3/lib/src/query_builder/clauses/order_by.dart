import '../compiler.dart';
import '../expressions/expression.dart';
import '../expressions/functions.dart';

/// Describes how to order rows
enum OrderingMode {
  /// Ascending ordering mode (lowest items first)
  asc._('ASC'),

  /// Descending ordering mode (highest items first)
  desc._('DESC');

  /// The lexeme to use for this [OrderingMode] option in SQL.
  final String lexeme;

  const OrderingMode._(this.lexeme);
}

/// Describes how to order nulls
enum NullsOrder {
  /// Place NULLs at the start
  first._('NULLS FIRST'),

  /// Place NULLs at the end
  last._('NULLS LAST');

  /// The lexeme to use for this [NullsOrder] option in SQL.
  final String lexeme;

  const NullsOrder._(this.lexeme);
}

/// A single term in a [OrderBy] clause. The priority of this term is determined
/// by its position in [OrderBy.terms].
final class OrderingTerm implements SqlComponent {
  /// The expression with which different rows should be compared.
  final Expression expression;

  /// The ordering mode (ascending or descending).
  final OrderingMode mode;

  /// How to order NULLs.
  /// When [nulls] is [null], then it's ignored.
  ///
  /// Note that this feature are only available in sqlite3 version `3.30.0` and
  /// newer. When using `sqlite3_flutter_libs` or a web database, this is not
  /// a problem.
  final NullsOrder? nulls;

  /// Creates an ordering term by the [expression], the [mode] (defaults to
  /// ascending) and the [nulls].
  OrderingTerm({
    required this.expression,
    this.mode = OrderingMode.asc,
    this.nulls,
  });

  /// Creates an ordering term that sorts for ascending values
  /// of [expression] and the [nulls].
  factory OrderingTerm.asc(Expression expression, {NullsOrder? nulls}) {
    return OrderingTerm(
      expression: expression,
      mode: OrderingMode.asc,
      nulls: nulls,
    );
  }

  /// Creates an ordering term that sorts for descending values
  /// of [expression] and the [nulls].
  factory OrderingTerm.desc(Expression expression, {NullsOrder? nulls}) {
    return OrderingTerm(
      expression: expression,
      mode: OrderingMode.desc,
      nulls: nulls,
    );
  }

  /// Creates an ordering term that sorts rows in a random order
  /// using sqlite random function.
  factory OrderingTerm.random() {
    return OrderingTerm(expression: const FunctionCallExpression('random', []));
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addOrderingTerm(this);
  }
}

/// An order-by clause as part of a select statement. The clause can consist
/// of multiple [OrderingTerm]s, with the first terms being more important and
/// the later terms only being considered if the first term considers two rows
/// equal.
final class OrderBy implements SqlComponent {
  /// The list of ordering terms to respect. Terms appearing earlier in this
  /// list are more important, the others will only considered when two rows
  /// are equal by the first [OrderingTerm].
  final List<OrderingTerm> terms;

  /// Constructs an order by clause by the [terms].
  const OrderBy(this.terms);

  /// Orders by nothing.
  ///
  /// In this case, the ordering of result rows is undefined.
  const OrderBy.nothing() : this(const []);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addOrderBy(this);
  }
}
