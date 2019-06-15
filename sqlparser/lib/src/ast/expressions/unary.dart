import 'package:sqlparser/src/reader/tokenizer/token.dart';

import 'expressions.dart';

class UnaryExpression extends Expression {
  final Token operator;
  final Expression inner;

  UnaryExpression(this.operator, this.inner);
}
