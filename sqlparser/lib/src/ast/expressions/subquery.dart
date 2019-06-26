part of '../ast.dart';

/// A subquery, which is an expression. It is expected that the inner query
/// only returns one column and one row.
class SubQuery extends Expression {
  final SelectStatement select;

  SubQuery({this.select});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitSubQuery(this);

  @override
  Iterable<AstNode> get childNodes => [select];

  @override
  bool contentEquals(SubQuery other) => true;
}
