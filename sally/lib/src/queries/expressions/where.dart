import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/generation_context.dart';
import 'package:sally/src/queries/predicates/predicate.dart';

class WhereExpression extends SqlExpression {
  final Predicate predicate;

  WhereExpression(this.predicate);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write("WHERE ");
    predicate.writeInto(context);
  }
}
