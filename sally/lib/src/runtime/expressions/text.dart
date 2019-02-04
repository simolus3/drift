import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/sql_types.dart';

class LikeOperator extends Expression<BoolType> {
  final Expression<StringType> target;
  final Expression<StringType> regex;

  LikeOperator(this.target, this.regex);

  @override
  void writeInto(GenerationContext context) {
    target.writeInto(context);
    context.buffer.write(' LIKE ');
    regex.writeInto(context);
  }
}
