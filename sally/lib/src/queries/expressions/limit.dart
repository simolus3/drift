import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/generation_context.dart';

class LimitExpression extends SqlExpression {
  final int amount;
  final int offset;

  LimitExpression(this.amount, this.offset);

  @override
  void writeInto(GenerationContext context) {
    if (offset != null)
      context.buffer.write('LIMIT $amount, $offset ');
    else
      context.buffer.write('LIMIT $amount ');
  }
}
