import 'package:meta/meta.dart';

import '../compiler.dart';
import 'expression.dart';

@immutable
final class ExpressionTuple<T extends Object> extends Expression {
  final List<Expression<T>> values;

  ExpressionTuple(this.values) : assert(values.isNotEmpty);

  @override
  Precedence get precedence => Precedence.primary;

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addTuple(this);
  }
}
