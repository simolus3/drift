part of '../ast.dart';

class UnaryExpression extends Expression {
  final Token operator;
  final Expression inner;

  UnaryExpression(this.operator, this.inner);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitUnaryExpression(this);

  @override
  Iterable<AstNode> get childNodes => [inner];

  @override
  bool contentEquals(UnaryExpression other) {
    return other.operator.type == operator.type;
  }
}

class BinaryExpression extends Expression {
  final Token operator;
  final Expression left;
  final Expression right;

  BinaryExpression(this.left, this.operator, this.right);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitBinaryExpression(this);

  @override
  Iterable<AstNode> get childNodes => [left, right];

  @override
  bool contentEquals(BinaryExpression other) {
    return other.operator.type == operator.type;
  }
}

class IsExpression extends Expression {
  final bool negated;
  final Expression left;
  final Expression right;

  IsExpression(this.negated, this.left, this.right);

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitIsExpression(this);
  }

  @override
  Iterable<AstNode> get childNodes => [left, right];

  @override
  bool contentEquals(IsExpression other) {
    return other.negated == negated;
  }
}

class BetweenExpression extends Expression {
  final bool not;
  final Expression check;
  final Expression lower;
  final Expression upper;

  BetweenExpression({this.not = false, this.check, this.lower, this.upper});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitBetweenExpression(this);

  @override
  Iterable<AstNode> get childNodes => [check, lower, upper];

  @override
  bool contentEquals(BetweenExpression other) => other.not == not;
}

class Parentheses extends Expression {
  final Token openingLeft;
  final Expression expression;
  final Token closingRight;

  Parentheses(this.openingLeft, this.expression, this.closingRight);

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return expression.accept(visitor);
  }

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool contentEquals(Parentheses other) => true;
}
