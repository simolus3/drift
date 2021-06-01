part of '../ast.dart';

/// Base for `ORDER BY` clauses. Without moor extensions, ony [OrderBy] will be
/// parsed. Otherwise, [DartOrderByPlaceholder] can be parsed as well.
abstract class OrderByBase extends AstNode {}

/// Base for a single ordering term that is a part of a [OrderBy]. Without moor
/// extensions, only [OrderingTerm] will be parsed. With moor extensions, a
/// [DartOrderingTermPlaceholder] can be parsed as well.
abstract class OrderingTermBase extends AstNode {}

class OrderBy extends AstNode implements OrderByBase {
  List<OrderingTermBase> terms;

  OrderBy({this.terms = const []});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitOrderBy(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    terms = transformer.transformChildren(terms, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => terms;
}

enum OrderingMode { ascending, descending }

enum OrderingBehaviorForNulls { first, last }

class OrderingTerm extends AstNode implements OrderingTermBase {
  Expression expression;
  OrderingMode? orderingMode;
  OrderingBehaviorForNulls? nulls;

  OrderingMode get resolvedOrderingMode =>
      orderingMode ?? OrderingMode.ascending;

  OrderingTerm({required this.expression, this.orderingMode, this.nulls});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitOrderingTerm(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    expression = transformer.transformChild(expression, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [expression];
}
