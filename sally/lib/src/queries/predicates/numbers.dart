import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/generation_context.dart';
import 'package:sally/src/queries/predicates/predicate.dart';

enum ComparisonOperator { less, less_or_equal, more, more_or_equal }

class NumberComparisonPredicate extends Predicate {
  static const Map<ComparisonOperator, String> _operators = {
    ComparisonOperator.less: '< ',
    ComparisonOperator.less_or_equal: '<= ',
    ComparisonOperator.more: '> ',
    ComparisonOperator.more_or_equal: '>= ',
  };

  SqlExpression left;
  ComparisonOperator operator;
  SqlExpression right;

  NumberComparisonPredicate(this.left, this.operator, this.right);

  @override
  void writeInto(GenerationContext context) {
    left.writeInto(context);
    context.buffer.write(_operators[operator]);
    right.writeInto(context);
  }
}
