import 'package:meta/meta.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';

enum OrderingMode {
  /// Ascending ordering mode (lowest items first)
  asc,
  /// Descending ordering mode (highest items first)
  desc
}

const _modeToString = {
  OrderingMode.asc: 'ASC',
  OrderingMode.desc: 'DESC',
};

/// A single term in a [OrderBy] clause. The priority of this term is determined
/// by its position in [OrderBy.terms].
class OrderingTerm extends Component {

  /// The expression after which the ordering should happen
  final Expression expression;
  /// The ordering mode (ascending or descending).
  final OrderingMode mode;

  OrderingTerm({@required this.expression, this.mode = OrderingMode.asc});

  @override
  void writeInto(GenerationContext context) {
    expression.writeInto(context);
    context.writeWhitespace();
    context.buffer.write(_modeToString[mode]);
  }

}

/// An order-by clause as part of a select statement. The clause can consist
/// of multiple [OrderingTerm]s, with the first terms being more important and
/// the later terms only being considered if the first term considers two rows
/// equal.
class OrderBy extends Component {

  final List<OrderingTerm> terms;

  OrderBy(this.terms);

  @override
  void writeInto(GenerationContext context) {
    var first = true;

    context.buffer.write('ORDER BY ');

    for (var term in terms) {
      if (first) {
        first = false;
      } else {
        context.buffer.write(', ');
      }

      term.writeInto(context);
    }
  }

}