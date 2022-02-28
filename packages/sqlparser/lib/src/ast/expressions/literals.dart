part of '../ast.dart';
// https://www.sqlite.org/syntax/literal-value.html

@optionalTypeArgs
abstract class Literal<T> extends Expression {
  final Token token;
  T get value;

  Literal(this.token);

  @override
  final Iterable<AstNode> childNodes = const <AstNode>[];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  String toString() {
    return 'Literal with value $value';
  }
}

class NullLiteral<T> extends Literal {
  NullLiteral(Token token) : super(token);

  @override
  Null get value => null;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitNullLiteral(this, arg);
  }
}

class NumericLiteral extends Literal<num> {
  @override
  final num value;

  bool get isInt => value is int;

  NumericLiteral(this.value, Token token) : super(token);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitNumericLiteral(this, arg);
  }
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
  dynamic get value => throw UnimplementedError('TimeConstantLiteral.value');
}
