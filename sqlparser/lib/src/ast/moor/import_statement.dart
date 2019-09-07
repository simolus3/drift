part of '../ast.dart';

class ImportStatement extends Statement {
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
