import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/generation_context.dart';

class Variable extends SqlExpression {
  final dynamic value;

  Variable(this.value);

  @override
  void writeInto(GenerationContext context) {
    context.addBoundVariable(value);

    context.buffer.write('? ');
  }
}

class HardcodedConstant extends SqlExpression {

  final dynamic value;

  HardcodedConstant(this.value);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(context.harcodedSqlValue(value));
  }

}
