part of '../query_builder.dart';

/// Describes how to order rows
enum OrderingMode {
  /// Ascending ordering mode (lowest items first)
  asc._('ASC'),

  /// Descending ordering mode (highest items first)
  desc._('DESC');

  final String _mode;

  const OrderingMode._(this._mode);
}

/// Describes how to order nulls
enum NullsOrder {
  /// Place NULLs at the start
  first._('NULLS FIRST'),

  /// Place NULLs at the end
  last._('NULLS LAST');

  final String _order;

  const NullsOrder._(this._order);
}

/// A single term in a [OrderBy] clause. The priority of this term is determined
/// by its position in [OrderBy.terms].
class OrderingTerm extends Component {
  /// The expression after which the ordering should happen
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
  void writeInto(GenerationContext context) {
    expression.writeInto(context);
    context.writeWhitespace();
    context.buffer.write(mode._mode);
    if (nulls != null) {
      context.writeWhitespace();
      context.buffer.write(nulls?._order);
    }
  }
}

/// An order-by clause as part of a select statement. The clause can consist
/// of multiple [OrderingTerm]s, with the first terms being more important and
/// the later terms only being considered if the first term considers two rows
/// equal.
class OrderBy extends Component {
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
  void writeInto(GenerationContext context) {
    if (terms.isEmpty) return;

    context.buffer.write('ORDER BY ');
    _writeCommaSeparated(context, terms);
  }
}
