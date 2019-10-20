part of '../ast.dart';

/// BLOCK = 'BEGIN' < CRUD-STATEMENT ';' > 'END'
class Block extends AstNode {
  Token begin;
  Token end;
  final List<CrudStatement> statements;

  Block(this.statements);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitBlock(this);

  @override
  Iterable<AstNode> get childNodes => statements;

  @override
  bool contentEquals(Block other) => true;
}
