part of '../ast.dart';

/// Something that can appear as a top-level declaration inside a `.moor` file.
abstract class PartOfMoorFile implements Statement {}

/// A moor file.
///
/// A moor file consists of [ImportStatement], followed by ddl statements,
/// followed by [DeclaredStatement]s.
class MoorFile extends AstNode {
  final List<PartOfMoorFile> statements;

  MoorFile(this.statements);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitMoorFile(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => statements;

  /// Returns the imports defined in this file.
  Iterable<ImportStatement> get imports =>
      childNodes.whereType<ImportStatement>();

  @override
  bool contentEquals(MoorFile other) => true;
}
