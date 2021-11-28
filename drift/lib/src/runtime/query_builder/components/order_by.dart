part of '../query_builder.dart';

/// Describes how to order rows
enum OrderingMode {
  /// Ascending ordering mode (lowest items first)
  asc,

  /// Descending ordering mode (highest items first)
  desc,

  /// Random ordering mode
  random,
}

const _modeToString = {
  OrderingMode.asc: 'ASC',
  OrderingMode.desc: 'DESC',
  OrderingMode.random: 'RANDOM()',
};

/// A single term in a [OrderBy] clause. The priority of this term is determined
/// by its position in [OrderBy.terms].
class OrderingTerm extends Component {
  /// The expression after which the ordering should happen
  final Expression? _expression;

  /// The ordering mode (ascending or descending).
  final OrderingMode mode;

  /// Creates an ordering term by the [expression] and the [mode] (defaults to
  /// ascending).
  ///
  /// When [mode] is [OrderingMode.random], the [expression] will be ignored
  OrderingTerm({required Expression expression, this.mode = OrderingMode.asc})
      : _expression = expression;

  /// Creates an ordering term that sorts for ascending values of [expression].
  factory OrderingTerm.asc(Expression expression) {
    return OrderingTerm(expression: expression, mode: OrderingMode.asc);
  }

  /// Creates an ordering term that sorts for descending values of [expression].
  factory OrderingTerm.desc(Expression expression) {
    return OrderingTerm(expression: expression, mode: OrderingMode.desc);
  }

  /// Creates an ordering term  to get a number of random rows
  /// using sqlite random function.
  OrderingTerm.random()
      : _expression = null,
        mode = OrderingMode.random;

  @override
  void writeInto(GenerationContext context) {
    if (mode != OrderingMode.random) {
      _expression!.writeInto(context);
    }
    context.buffer.write(_modeToString[mode]);
    context.writeWhitespace();
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
