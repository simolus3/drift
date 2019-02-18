import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/sql_types.dart';

Expression<bool, BoolType> and(
        Expression<bool, BoolType> a, Expression<bool, BoolType> b) =>
    AndExpression(a, b);

Expression<bool, BoolType> or(
        Expression<bool, BoolType> a, Expression<bool, BoolType> b) =>
    OrExpression(a, b);

Expression<bool, BoolType> not(Expression<bool, BoolType> a) =>
    NotExpression(a);

class AndExpression extends InfixOperator<bool, BoolType> {
  @override
  Expression<bool, BoolType> left, right;

  @override
  final String operator = 'AND';

  AndExpression(this.left, this.right);
}

class OrExpression extends InfixOperator<bool, BoolType> {
  @override
  Expression<bool, BoolType> left, right;

  @override
  final String operator = 'OR';

  OrExpression(this.left, this.right);
}

class NotExpression extends Expression<bool, BoolType> {
  Expression<bool, BoolType> inner;

  NotExpression(this.inner);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('NOT ');
    inner.writeInto(context);
  }
}
