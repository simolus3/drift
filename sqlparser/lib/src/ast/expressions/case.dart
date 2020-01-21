part of '../ast.dart';

class CaseExpression extends Expression {
  final Expression base; // can be null
  final List<WhenComponent> whens;
  final Expression elseExpr;

  CaseExpression({this.base, @required this.whens, this.elseExpr});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCaseExpression(this, arg);
  }

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
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitWhen(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [when, then];

  @override
  bool contentEquals(WhenComponent other) => true;
}
