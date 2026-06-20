import '../../reader/tokenizer/token.dart';
import '../ast.dart';

/// An inline Dart component that appears in a compiled sql query. Inline Dart
/// components can be bound with complex expressions at runtime by using drift's
/// Dart API.
///
/// At the moment, we support 4 kind of inline components:
///  1. expressions: Any expression can be used for drift: `SELECT * FROM table
///  = $expr`. Generated code will write this as an `Expression` class from
///  drift.
///  2. limits, which will be exposed as a `Limit` component from drift
///  3. A single order-by clause, which will be exposed as a `OrderingTerm` from
///  drift.
///  4. A list of order-by clauses, which will be exposed as a `OrderBy` from
///  drift.
sealed class DartPlaceholder extends AstNode implements DriftSpecificNode {
  final String name;

  DollarSignVariableToken? token;

  DartPlaceholder._(this.name);

  @override
  final Iterable<AstNode> childNodes = const Iterable.empty();

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDriftSpecificNode(this, arg);
  }
}

class DartExpressionPlaceholder extends DartPlaceholder implements Expression {
  DartExpressionPlaceholder({required String name}) : super._(name);
}

class DartLimitPlaceholder extends DartPlaceholder implements LimitBase {
  DartLimitPlaceholder({required String name}) : super._(name);
}

class DartOrderingTermPlaceholder extends DartPlaceholder
    implements OrderingTermBase {
  DartOrderingTermPlaceholder({required String name}) : super._(name);
}

class DartOrderByPlaceholder extends DartPlaceholder implements OrderByBase {
  DartOrderByPlaceholder({required String name}) : super._(name);
}

class DartInsertablePlaceholder extends DartPlaceholder
    implements InsertSource, SetComponent {
  DartInsertablePlaceholder({required String name}) : super._(name);

  /// Placeholders in [UpdateStatement] will generate columns dynamically at runtime.
  @override
  List<Reference> get columns => const [];
}
