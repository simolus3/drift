part of '../ast.dart';

/// BLOCK = 'BEGIN' < CRUD-STATEMENT ';' > 'END'
class Block extends AstNode {
  Token? begin;
  Token? end;
  final List<CrudStatement> statements;

  Block(this.statements);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitBlock(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(statements, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => statements;
}
