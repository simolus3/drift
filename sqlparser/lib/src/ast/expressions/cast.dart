part of '../ast.dart';

/// A `CAST(<expr> AS <type>)` expression.
class CastExpression extends Expression {
  Expression operand;
  final String typeName;

  CastExpression(this.operand, this.typeName);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCastExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    operand = transformer.transformChild(operand, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [operand];
}
