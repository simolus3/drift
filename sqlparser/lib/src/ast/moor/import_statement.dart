part of '../ast.dart';

/// An `import "file.dart";` statement that can appear inside a moor file.
class ImportStatement extends Statement implements PartOfMoorFile {
  Token importToken;
  StringLiteralToken importString;
  final String importedFile;

  ImportStatement(this.importedFile);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitMoorImportStatement(this, arg);
  }

  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  bool contentEquals(ImportStatement other) {
    return other.importedFile == importedFile;
  }
}
