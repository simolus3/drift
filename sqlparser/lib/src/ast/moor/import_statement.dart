part of '../ast.dart';

/// An `import "file.dart";` statement that can appear inside a moor file.
class ImportStatement extends Statement implements PartOfMoorFile {
  Token importToken;
  StringLiteralToken importString;
  final String importedFile;

  ImportStatement(this.importedFile);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitMoorImportStatement(this);

  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  bool contentEquals(ImportStatement other) {
    return other.importedFile == importedFile;
  }
}
