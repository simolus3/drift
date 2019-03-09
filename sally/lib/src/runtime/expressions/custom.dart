import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';

class CustomExpression<D, S extends SqlType<D>> extends Expression<D, S> {
  final String content;

  CustomExpression(this.content);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(content);
  }
}
