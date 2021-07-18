part of 'declaration.dart';

abstract class ColumnDeclaration extends Declaration {
  /// Whether this column was declared in a moor file (e.g. in a `CREATE TABLE`
  /// statement).
  bool get isDefinedInMoorFile;
}

class DartColumnDeclaration implements DartDeclaration, ColumnDeclaration {
  @override
  final SourceRange declaration;

  /// In the Dart api, columns declared via getters.
  @override
  final Element element;

  DartColumnDeclaration._(this.declaration, this.element);

  factory DartColumnDeclaration(Element element, FoundFile file) {
    return DartColumnDeclaration._(
      SourceRange.fromElementAndFile(element, file),
      element,
    );
  }

  @override
  bool get isDefinedInMoorFile => false;
}

class MoorColumnDeclaration implements MoorDeclaration, ColumnDeclaration {
  @override
  final SourceRange declaration;

  @override
  final AstNode node;

  MoorColumnDeclaration._(this.declaration, this.node);

  factory MoorColumnDeclaration(AstNode node, FoundFile file) {
    return MoorColumnDeclaration._(
      SourceRange.fromNodeAndFile(node, file),
      node,
    );
  }

  @override
  bool get isDefinedInMoorFile => true;
}
