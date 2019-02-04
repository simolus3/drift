import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/sql_types.dart';

class Where extends Component {
  final Expression<BoolType> predicate;

  Where(this.predicate);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write("WHERE ");
    predicate.writeInto(context);
  }
}
