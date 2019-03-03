import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/types/sql_types.dart';

/// Returns an expression that is true iff both [a] and [b] are true.
Expression<bool, BoolType> and(
        Expression<bool, BoolType> a, Expression<bool, BoolType> b) =>
    _AndExpression(a, b);

/// Returns an expression that is true iff [a], [b] or both are true.
Expression<bool, BoolType> or(
        Expression<bool, BoolType> a, Expression<bool, BoolType> b) =>
    _OrExpression(a, b);

/// Returns an expression that is true iff [a] is not true.
Expression<bool, BoolType> not(Expression<bool, BoolType> a) =>
    _NotExpression(a);

class _AndExpression extends InfixOperator<bool, BoolType> {
  @override
  Expression<bool, BoolType> left, right;

  @override
  final String operator = 'AND';

  _AndExpression(this.left, this.right);
}

class _OrExpression extends InfixOperator<bool, BoolType> {
  @override
  Expression<bool, BoolType> left, right;

  @override
  final String operator = 'OR';

  _OrExpression(this.left, this.right);
}

class _NotExpression extends Expression<bool, BoolType> {
  Expression<bool, BoolType> inner;

  _NotExpression(this.inner);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('NOT ');
    inner.writeInto(context);
  }
}
