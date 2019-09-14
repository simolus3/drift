part of '../ast.dart';

/// Base for `ORDER BY` clauses. Without moor extensions, ony [OrderBy] will be
/// parsed. Otherwise, [DartOrderByPlaceholder] can be parsed as well.
abstract class OrderByBase extends AstNode {}

/// Base for a single ordering term that is a part of a [OrderBy]. Without moor
/// extensions, only [OrderingTerm] will be parsed. With moor extensions, a
/// [DartOrderingTermPlaceholder] can be parsed as well.
abstract class OrderingTermBase extends AstNode {}

class OrderBy extends AstNode implements OrderByBase {
  final List<OrderingTermBase> terms;

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

class OrderingTerm extends AstNode implements OrderingTermBase {
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
