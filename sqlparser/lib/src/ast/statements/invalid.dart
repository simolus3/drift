part of '../ast.dart';

/// Used as a top-level substitute when no statement could be parsed otherwise.
class InvalidStatement extends Statement {
  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitInvalidStatement(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const Iterable.empty();

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}
