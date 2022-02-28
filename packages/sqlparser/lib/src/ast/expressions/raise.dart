import '../node.dart';
import '../visitor.dart';
import 'expressions.dart';

enum RaiseKind {
  ignore,
  rollback,
  abort,
  fail,
}

class RaiseExpression extends Expression {
  final RaiseKind raiseKind;

  /// The user-defined error message for this `RAISE` expression.
  ///
  /// This will be non-null if [raiseKind] is not [RaiseKind.ignore].
  final String? errorMessage;

  RaiseExpression(this.raiseKind, [this.errorMessage]);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitRaiseExpression(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const Iterable.empty();

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}
