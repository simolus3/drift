part of '../ast.dart';

/// A declared statement inside a `.moor` file. It consists of an identifier,
/// followed by a colon and the query to run.
class DeclaredStatement extends Statement {
  final String name;
  final CrudStatement statement;

  IdentifierToken identifier;
  Token colon;

  DeclaredStatement(this.name, this.statement);

  @override
  T accept<T>(AstVisitor<T> visitor) =>
      visitor.visitMoorDeclaredStatement(this);

  @override
  Iterable<AstNode> get childNodes => [statement];

  @override
  bool contentEquals(DeclaredStatement other) {
    return other.name == name;
  }
}
