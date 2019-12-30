part of 'declaration.dart';

abstract class TableDeclaration extends Declaration {}

class DartTableDeclaration implements TableDeclaration, DartDeclaration {
  @override
  final SourceRange declaration;

  @override
  final ClassElement element;

  DartTableDeclaration._(this.declaration, this.element);

  factory DartTableDeclaration(ClassElement element, FoundFile file) {
    return DartTableDeclaration._(
      SourceRange.fromElementAndFile(element, file),
      element,
    );
  }
}

class MoorTableDeclaration implements TableDeclaration, MoorDeclaration {
  @override
  final SourceRange declaration;

  @override
  final TableInducingStatement node;

  MoorTableDeclaration._(this.declaration, this.node);

  factory MoorTableDeclaration(TableInducingStatement node, FoundFile file) {
    return MoorTableDeclaration._(
      SourceRange.fromNodeAndFile(node, file),
      node,
    );
  }
}
