part of '../ast.dart';

class OrderBy extends AstNode {
  final List<OrderingTerm> terms;

  OrderBy({this.terms});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitOrderBy(this);

  @override
  Iterable<AstNode> get childNodes => terms;

  @override
  bool contentEquals(OrderBy other) {
    return true;
  }
}

enum OrderingMode { ascending, descending }

class OrderingTerm extends AstNode {
  final Expression expression;
  final OrderingMode orderingMode;

  OrderingMode get resolvedOrderingMode =>
      orderingMode ?? OrderingMode.ascending;

  OrderingTerm({this.expression, this.orderingMode});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitOrderingTerm(this);

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool contentEquals(OrderingTerm other) {
    return other.orderingMode == orderingMode;
  }
}
