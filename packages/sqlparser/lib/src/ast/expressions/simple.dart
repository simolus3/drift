part of '../ast.dart';

class UnaryExpression extends Expression {
  final Token operator;
  Expression inner;

  UnaryExpression(this.operator, this.inner);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitUnaryExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    inner = transformer.transformChild(inner, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [inner];
}

class CollateExpression extends UnaryExpression {
  final Token collateFunction;

  String get collation => collateFunction.lexeme;

  CollateExpression(
      {required Token operator,
      required Expression inner,
      required this.collateFunction})
      : super(operator, inner);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCollateExpression(this, arg);
  }
}

class BinaryExpression extends Expression {
  final Token operator;
  Expression left;
  Expression right;

  BinaryExpression(this.left, this.operator, this.right);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitBinaryExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    left = transformer.transformChild(left, this, arg);
    right = transformer.transformChild(right, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [left, right];
}

/// A like, glob, match or regexp expression.
class StringComparisonExpression extends Expression {
  final bool not;
  final Token operator;
  Expression left;
  Expression right;
  Expression? escape;

  StringComparisonExpression(
      {this.not = false,
      required this.left,
      required this.operator,
      required this.right,
      this.escape});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitStringComparison(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    left = transformer.transformChild(left, this, arg);
    right = transformer.transformChild(right, this, arg);
    escape = transformer.transformNullableChild(escape, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes =>
      [left, right, if (escape != null) escape!];
}

/// `(NOT)? $left IS $right`
class IsExpression extends Expression {
  final bool negated;
  Expression left;
  Expression right;

  IsExpression(this.negated, this.left, this.right);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitIsExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    left = transformer.transformChild(left, this, arg);
    right = transformer.transformChild(right, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [left, right];
}

class IsNullExpression extends Expression {
  Expression operand;

  /// When true, this is a `NOT NULL` expression.
  final bool negated;

  IsNullExpression(this.operand, [this.negated = false]);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitIsNullExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    operand = transformer.transformChild(operand, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [operand];
}

/// `$check BETWEEN $lower AND $upper`
class BetweenExpression extends Expression {
  final bool not;
  Expression check;
  Expression lower;
  Expression upper;

  BetweenExpression(
      {this.not = false,
      required this.check,
      required this.lower,
      required this.upper});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitBetweenExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    check = transformer.transformChild(check, this, arg);
    lower = transformer.transformChild(lower, this, arg);
    upper = transformer.transformChild(upper, this, arg);
  }

  @override
  List<Expression> get childNodes => [check, lower, upper];
}

/// `$left$ IN $inside`.
class InExpression extends Expression {
  final bool not;
  Expression left;

  /// The right-hand part: Contains the set of values [left] will be tested
  /// against. From the sqlite grammar, we support [Tuple] and a [SubQuery].
  /// We also support a [Variable] as syntax sugar - it will be expanded into a
  /// tuple of variables at runtime.
  Expression inside;

  InExpression({this.not = false, required this.left, required this.inside})
      : assert(inside is Tuple || inside is Variable || inside is SubQuery);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitInExpression(this, arg);
  }

  @override
  List<Expression> get childNodes => [left, inside];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    left = transformer.transformChild(left, this, arg);
    inside = transformer.transformChild(inside, this, arg);
  }
}

class Parentheses extends Expression {
  Token? openingLeft;
  Token? closingRight;
  Expression expression;

  Parentheses(this.expression);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitParentheses(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    expression = transformer.transformChild(expression, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [expression];
}
