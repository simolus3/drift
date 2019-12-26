part of '../ast.dart';

class UnaryExpression extends Expression {
  final Token operator;
  final Expression inner;

  UnaryExpression(this.operator, this.inner);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitUnaryExpression(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [inner];

  @override
  bool contentEquals(UnaryExpression other) {
    return other.operator.type == operator.type;
  }
}

class CollateExpression extends UnaryExpression {
  final Token collateFunction;

  CollateExpression(
      {@required Token operator,
      @required Expression inner,
      @required this.collateFunction})
      : super(operator, inner);

  @override
  bool contentEquals(CollateExpression other) {
    return super.contentEquals(other) &&
        other.collateFunction.type == collateFunction.type;
  }
}

class BinaryExpression extends Expression {
  final Token operator;
  final Expression left;
  final Expression right;

  BinaryExpression(this.left, this.operator, this.right);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitBinaryExpression(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [left, right];

  @override
  bool contentEquals(BinaryExpression other) {
    return other.operator.type == operator.type;
  }
}

class StringComparisonExpression extends Expression {
  final bool not;
  final Token operator;
  final Expression left;
  final Expression right;
  final Expression escape;

  StringComparisonExpression(
      {this.not = false,
      @required this.left,
      @required this.operator,
      @required this.right,
      this.escape});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitStringComparison(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [left, right, if (escape != null) escape];

  @override
  bool contentEquals(StringComparisonExpression other) => other.not == not;
}

/// `(NOT)? $left IS $right`
class IsExpression extends Expression {
  final bool negated;
  final Expression left;
  final Expression right;

  IsExpression(this.negated, this.left, this.right);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitIsExpression(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [left, right];

  @override
  bool contentEquals(IsExpression other) {
    return other.negated == negated;
  }
}

/// `$check BETWEEN $lower AND $upper`
class BetweenExpression extends Expression {
  final bool not;
  final Expression check;
  final Expression lower;
  final Expression upper;

  BetweenExpression({this.not = false, this.check, this.lower, this.upper});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitBetweenExpression(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [check, lower, upper];

  @override
  bool contentEquals(BetweenExpression other) => other.not == not;
}

/// `$left$ IN $inside`.
class InExpression extends Expression {
  final bool not;
  final Expression left;

  /// The right-hand part: Contains the set of values [left] will be tested
  /// against. From the sqlite grammar, we support [Tuple] and a [SubQuery].
  /// We also support a [Variable] as syntax sugar - it will be expanded into a
  /// tuple of variables at runtime.
  final Expression inside;

  InExpression({this.not = false, @required this.left, @required this.inside})
      : assert(inside is Tuple || inside is Variable || inside is SubQuery);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitInExpression(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [left, inside];

  @override
  bool contentEquals(InExpression other) => other.not == not;
}

// todo we might be able to remove a hack in the parser at _in() if we make
// parentheses a subclass of tuples

class Parentheses extends Expression {
  final Token openingLeft;
  final Expression expression;
  final Token closingRight;

  Parentheses(this.openingLeft, this.expression, this.closingRight) {
    setSpan(openingLeft, closingRight);
  }

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return expression.accept(visitor, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool contentEquals(Parentheses other) => true;
}
