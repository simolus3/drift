import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/types/sql_types.dart';

/// A `text LIKE pattern` expression that will be true if the first expression
/// matches the pattern given by the second expression.
class LikeOperator extends Expression<bool, BoolType> {
  final Expression<String, StringType> target;
  final Expression<String, StringType> regex;

  LikeOperator(this.target, this.regex);

  @override
  void writeInto(GenerationContext context) {
    target.writeInto(context);
    context.buffer.write(' LIKE ');
    regex.writeInto(context);
  }
}
