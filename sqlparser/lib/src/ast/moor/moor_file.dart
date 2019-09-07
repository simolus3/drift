part of '../ast.dart';

/// Something that can appear as a top-level declaration inside a `.moor` file.
abstract class PartOfMoorFile implements Statement {}

class MoorFile extends AstNode {
  final List<PartOfMoorFile> statements;

  MoorFile(this.statements);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitMoorFile(this);

  @override
  Iterable<AstNode> get childNodes => statements;

  @override
  bool contentEquals(MoorFile other) => true;
}
