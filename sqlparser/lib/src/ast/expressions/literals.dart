import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

import 'expressions.dart';

// https://www.sqlite.org/syntax/literal-value.html

abstract class Literal extends Expression {
  final Token token;

  Literal(this.token);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitLiteral(this);

  @override
  final Iterable<AstNode> childNodes = const <AstNode>[];
}

class NullLiteral extends Literal {
  NullLiteral(Token token) : super(token);
}

class NumericLiteral extends Literal {
  final num number;

  NumericLiteral(this.number, Token token) : super(token);
}

class BooleanLiteral extends NumericLiteral {
  BooleanLiteral.withFalse(Token token) : super(0, token);
  BooleanLiteral.withTrue(Token token) : super(1, token);
}

class StringLiteral extends Literal {
  final String data;
  final bool isBinary;

  StringLiteral(StringLiteralToken token)
      : data = token.value,
        isBinary = token.binary,
        super(token);
}
