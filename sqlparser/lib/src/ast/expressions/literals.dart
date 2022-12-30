part of '../ast.dart';
// https://www.sqlite.org/syntax/literal-value.html

@optionalTypeArgs
abstract class Literal<T> extends Expression {
  Token? token;
  T get value;

  Literal();

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

  NumericLiteral(this.value);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitNumericLiteral(this, arg);
  }
}

class BooleanLiteral extends Literal<bool> {
  @override
  final bool value;

  BooleanLiteral(this.value);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitBooleanLiteral(this, arg);
  }
}

class StringLiteral extends Literal {
  @override
  final String value;
  final bool isBinary;

  StringLiteral(this.value, {this.isBinary = false});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitStringLiteral(this, arg);
  }
}

enum TimeConstantKind { currentTime, currentDate, currentTimestamp }

class TimeConstantLiteral extends Literal {
  final TimeConstantKind kind;

  TimeConstantLiteral(this.kind);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitTimeConstantLiteral(this, arg);
  }

  @override
  dynamic get value => throw UnimplementedError('TimeConstantLiteral.value');
}
