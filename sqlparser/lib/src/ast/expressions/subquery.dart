part of '../ast.dart';

/// A subquery, which is an expression. It is expected that the inner query
/// only returns one column and one row.
class SubQuery extends Expression {
  final BaseSelectStatement select;

  SubQuery({this.select});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitSubQuery(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [select];

  @override
  bool contentEquals(SubQuery other) => true;
}

class ExistsExpression extends Expression {
  final BaseSelectStatement select;

  ExistsExpression({@required this.select});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitExists(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [select];

  @override
  bool contentEquals(ExistsExpression other) => true;
}
