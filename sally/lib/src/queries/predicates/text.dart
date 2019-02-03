import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/generation_context.dart';
import 'package:sally/src/queries/predicates/predicate.dart';

class LikePredicate extends Predicate {
  SqlExpression target;
  SqlExpression regex;

  LikePredicate(this.target, this.regex);

  @override
  void writeInto(GenerationContext context) {
    target.writeInto(context);
    context.buffer.write('LIKE ');
    regex.writeInto(context);
  }
}
