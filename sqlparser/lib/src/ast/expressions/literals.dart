part of '../ast.dart';
// https://www.sqlite.org/syntax/literal-value.html

@optionalTypeArgs
abstract class Literal<T> extends Expression {
  final Token token;
  T get value;

  Literal(this.token);

  @override
  final Iterable<AstNode> childNodes = const <AstNode>[];
}

class NullLiteral<T> extends Literal {
  NullLiteral(Token token) : super(token);

  @override
  Null get value => null;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitNullLiteral(this, arg);
  }

  @override
  bool contentEquals(NullLiteral other) => true;
}

class NumericLiteral extends Literal<num> {
  @override
  final num value;

  bool get isInt => value.toInt() == value;

  NumericLiteral(this.value, Token token) : super(token);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitNumericLiteral(this, arg);
  }

  @override
  bool contentEquals(NumericLiteral other) => other.value == value;
}

class BooleanLiteral extends Literal<bool> {
  @override
  final bool value;

  BooleanLiteral.withFalse(Token token)
      : value = false,
        super(token);
  BooleanLiteral.withTrue(Token token)
      : value = true,
        super(token);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitBooleanLiteral(this, arg);
  }

  @override
  bool contentEquals(BooleanLiteral other) {
    return other.value == value;
  }
}

class StringLiteral extends Literal {
  @override
  final String value;
  final bool isBinary;

  StringLiteral(StringLiteralToken token)
      : value = token.value,
        isBinary = token.binary,
        super(token);

  StringLiteral.from(Token token, this.value, {this.isBinary = false})
      : super(token);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitStringLiteral(this, arg);
  }

  @override
  bool contentEquals(StringLiteral other) {
    return other.isBinary == isBinary && other.value == value;
  }
}

enum TimeConstantKind { currentTime, currentDate, currentTimestamp }

class TimeConstantLiteral extends Literal {
  final TimeConstantKind kind;

  TimeConstantLiteral(this.kind, Token keyword) : super(keyword);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitTimeConstantLiteral(this, arg);
  }

  @override
  bool contentEquals(TimeConstantLiteral other) {
    return other.kind == kind;
  }

  @override
  dynamic get value => throw UnimplementedError('TimeConstantLiteral.value');
}
