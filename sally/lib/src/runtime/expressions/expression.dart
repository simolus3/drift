import 'package:meta/meta.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/sql_types.dart';

/// Any sql expression that evaluates to some generic value. This does not
/// include queries (which might evaluate to multiple values) but individual
/// columns, functions and operators.
abstract class Expression<T extends SqlType> implements Component {}

/// An expression that looks like "$a operator $b$, where $a and $b itself
/// are expressions and operator is any string.
abstract class InfixOperator<T extends SqlType> implements Expression<T> {
  Expression get left;
  Expression get right;
  String get operator;

  @visibleForOverriding
  bool get placeBrackets => true;

  @override
  void writeInto(GenerationContext context) {
    _placeBracketIfNeeded(context, true);

    left.writeInto(context);

    _placeBracketIfNeeded(context, false);
    context.writeWhitespace();
    context.buffer.write(operator);
    context.writeWhitespace();
    _placeBracketIfNeeded(context, true);

    right.writeInto(context);

    _placeBracketIfNeeded(context, false);
  }

  void _placeBracketIfNeeded(GenerationContext context, bool open) {
    if (placeBrackets) context.buffer.write(open ? '(' : ')');
  }
}

enum ComparisonOperator { less, lessOrEqual, equal, moreOrEqual, more }

class Comparison extends InfixOperator<BoolType> {
  static const Map<ComparisonOperator, String> operatorNames = {
    ComparisonOperator.less: '<',
    ComparisonOperator.lessOrEqual: '<=',
    ComparisonOperator.equal: '=',
    ComparisonOperator.moreOrEqual: '>=',
    ComparisonOperator.more: '>'
  };

  @override
  final Expression left;
  @override
  final Expression right;
  final ComparisonOperator op;

  @override
  final bool placeBrackets = false;

  @override
  String get operator => operatorNames[op];

  Comparison(this.left, this.op, this.right);

  Comparison.equal(this.left, this.right) : op = ComparisonOperator.equal;
}
