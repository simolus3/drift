import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/sql_types.dart';

Expression<BoolType> and(Expression<BoolType> a, Expression<BoolType> b) =>
    AndExpression(a, b);

Expression<BoolType> not(Expression<BoolType> a) => NotExpression(a);

class AndExpression extends Expression<BoolType> with InfixOperator<BoolType> {
  Expression<BoolType> left, right;

  final String operator = "AND";

  AndExpression(this.left, this.right);
}

class OrExpression extends Expression<BoolType> with InfixOperator<BoolType> {
  Expression<BoolType> left, right;

  final String operator = "AND";

  OrExpression(this.left, this.right);
}

class NotExpression extends Expression<BoolType> {
  Expression<BoolType> inner;

  NotExpression(this.inner);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('NOT ');
    inner.writeInto(context);
  }
}
