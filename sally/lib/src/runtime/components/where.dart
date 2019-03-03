import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/types/sql_types.dart';

/// A where clause in a select, update or delete statement.
class Where extends Component {
  /// The expression that determines whether a given row should be included in
  /// the result.
  final Expression<bool, BoolType> predicate;

  Where(this.predicate);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('WHERE ');
    predicate.writeInto(context);
  }
}
