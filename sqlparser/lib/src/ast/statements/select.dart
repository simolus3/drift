part of '../ast.dart';

class SelectStatement extends AstNode {
  final Expression where;
  final Limit limit;

  SelectStatement({this.where, this.limit});

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitSelectStatement(this);
  }

  @override
  Iterable<AstNode> get childNodes => null;
}
