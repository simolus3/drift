export 'package:sally/src/queries/predicates/combining.dart';
export 'package:sally/src/queries/predicates/numbers.dart';
export 'package:sally/src/queries/predicates/text.dart';

import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/generation_context.dart';
import 'package:sally/src/queries/predicates/combining.dart';

Predicate not(Predicate p) => p.not();

abstract class Predicate extends SqlExpression {
  Predicate not() {
    return NotPredicate(this);
  }

  Predicate and(Predicate other) => AndPredicate(this, other);
  Predicate or(Predicate other) => OrPredicate(this, other);
}

class EqualityPredicate extends Predicate {
  SqlExpression left;
  SqlExpression right;

  EqualityPredicate(this.left, this.right);

  @override
  void writeInto(GenerationContext context) {
    left.writeInto(context);
    context.buffer.write('= ');
    right.writeInto(context);
  }
}

class BooleanExpressionPredicate extends Predicate {
  SqlExpression expression;

  BooleanExpressionPredicate(this.expression);

  @override
  void writeInto(GenerationContext context) {
    expression.writeInto(context);
  }
}
