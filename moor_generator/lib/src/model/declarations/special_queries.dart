//@dart=2.9
part of 'declaration.dart';

abstract class SpecialQueryDeclaration extends Declaration {}

class MoorSpecialQueryDeclaration
    implements MoorDeclaration, SpecialQueryDeclaration {
  @override
  final SourceRange declaration;

  @override
  final DeclaredStatement node;

  MoorSpecialQueryDeclaration.fromNodeAndFile(this.node, FoundFile file)
      : declaration = SourceRange.fromNodeAndFile(node, file);
}
