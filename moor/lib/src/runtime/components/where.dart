import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/expression.dart';
import 'package:moor/src/types/sql_types.dart';

/// A where clause in a select, update or delete statement.
class Where extends Component {
  /// The expression that determines whether a given row should be included in
  /// the result.
  final Expression<bool, BoolType> predicate;

  /// Construct a [Where] clause from its [predicate].
  Where(this.predicate);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('WHERE ');
    predicate.writeInto(context);
  }
}
