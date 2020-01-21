part of 'declaration.dart';

abstract class IndexDeclaration extends Declaration {}

class MoorIndexDeclaration implements MoorDeclaration, IndexDeclaration {
  @override
  final SourceRange declaration;

  @override
  final CreateIndexStatement node;

  MoorIndexDeclaration._(this.declaration, this.node);

  MoorIndexDeclaration.fromNodeAndFile(this.node, FoundFile file)
      : declaration = SourceRange.fromNodeAndFile(node, file);
}
