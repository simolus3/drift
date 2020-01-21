part of '../ast.dart';

/// A `CAST(<expr> AS <type>)` expression.
class CastExpression extends Expression {
  final Expression operand;
  final String typeName;

  CastExpression(this.operand, this.typeName);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCastExpression(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [operand];

  @override
  bool contentEquals(CastExpression other) {
    return other.typeName == typeName;
  }
}
