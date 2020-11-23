part of '../ast.dart';

class CaseExpression extends Expression {
  Expression /*?*/ base;
  final List<WhenComponent> whens;
  Expression /*?*/ elseExpr;

  CaseExpression({this.base, @required this.whens, this.elseExpr});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCaseExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    base = transformer.transformNullableChild(base, this, arg);
    transformer.transformChildren(whens, this, arg);
    elseExpr = transformer.transformNullableChild(elseExpr, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes =>
      [if (base != null) base, ...whens, if (elseExpr != null) elseExpr];
}

class WhenComponent extends AstNode {
  Expression when;
  Expression then;

  WhenComponent({this.when, this.then});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitWhen(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    when = transformer.transformChild(when, this, arg);
    then = transformer.transformChild(then, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [when, then];
}
