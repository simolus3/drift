part of '../ast.dart';

class CaseExpression extends Expression {
  final Expression base; // can be null
  final List<WhenComponent> whens;
  final Expression elseExpr;

  CaseExpression({this.base, @required this.whens, this.elseExpr});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitCaseExpression(this);

  @override
  Iterable<AstNode> get childNodes =>
      [if (base != null) base, ...whens, if (elseExpr != null) elseExpr];

  @override
  bool contentEquals(CaseExpression other) => true;
}

class WhenComponent extends AstNode {
  final Expression when;
  final Expression then;

  WhenComponent({this.when, this.then});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitWhen(this);

  @override
  Iterable<AstNode> get childNodes => [when, then];

  @override
  bool contentEquals(WhenComponent other) => true;
}
