part of '../ast.dart';

/// A tuple of values. For instance, in `SELECT * FROM t WHERE id IN (1,2,3)`,
/// the `(1,2,3)` is a tuple.
class TupleExpression extends Expression {
  /// The expressions appearing in this tuple.
  final List<Expression> expressions;

  TupleExpression({@required this.expressions});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitTuple(this);

  @override
  Iterable<AstNode> get childNodes => expressions;

  @override
  bool contentEquals(TupleExpression other) => true;
}
