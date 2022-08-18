part of 'declaration.dart';

abstract class SpecialQueryDeclaration extends Declaration {}

class DriftSpecialQueryDeclaration
    implements DriftFileDeclaration, SpecialQueryDeclaration {
  @override
  final SourceRange declaration;

  @override
  final DeclaredStatement node;

  DriftSpecialQueryDeclaration.fromNodeAndFile(this.node, FoundFile file)
      : declaration = SourceRange.fromNodeAndFile(node, file);
}
