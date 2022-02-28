part of '../ast.dart';

/// A subquery, which is an expression. It is expected that the inner query
/// only returns one column and one row.
class SubQuery extends Expression {
  BaseSelectStatement select;

  SubQuery({required this.select});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitSubQuery(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    select = transformer.transformChild(select, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [select];
}

class ExistsExpression extends Expression {
  BaseSelectStatement select;

  ExistsExpression({required this.select});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitExists(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    select = transformer.transformChild(select, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [select];
}
