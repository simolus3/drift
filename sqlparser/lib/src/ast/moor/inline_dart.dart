part of '../ast.dart';

/// An inline Dart component that appears in a compiled sql query. Inline Dart
/// components can be bound with complex expressions at runtime by using moor's
/// Dart API.
///
/// At the moment, we support 4 kind of inline components:
///  1. expressions: Any expression can be used for moor: `SELECT * FROM table
///  = $expr`. Generated code will write this as an `Expression` class from
///  moor.
///  2. limits
///  3. A single order-by clause
///  4. A list of order-by clauses
abstract class InlineDart extends AstNode {
  final String name;

  DollarSignVariableToken token;

  InlineDart._(this.name);

  @override
  final Iterable<AstNode> childNodes = const Iterable.empty();

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitInlineDartCode(this);

  bool _dartEquals(covariant InlineDart other);

  @override
  bool contentEquals(InlineDart other) {
    return other.name == name && other._dartEquals(other);
  }
}

class InlineDartExpression extends InlineDart implements Expression {
  InlineDartExpression({@required String name}) : super._(name);

  @override
  bool _dartEquals(InlineDartExpression other) => true;
}

class InlineDartLimit extends InlineDart implements LimitBase {
  InlineDartLimit({@required String name}) : super._(name);

  @override
  bool _dartEquals(InlineDartLimit other) => true;
}
