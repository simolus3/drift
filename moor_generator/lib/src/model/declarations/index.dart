//@dart=2.9
part of 'declaration.dart';

abstract class IndexDeclaration extends Declaration {}

class MoorIndexDeclaration implements MoorDeclaration, IndexDeclaration {
  @override
  final SourceRange declaration;

  @override
  final CreateIndexStatement node;

  MoorIndexDeclaration.fromNodeAndFile(this.node, FoundFile file)
      : declaration = SourceRange.fromNodeAndFile(node, file);
}
