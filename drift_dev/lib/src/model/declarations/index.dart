part of 'declaration.dart';

abstract class IndexDeclaration extends Declaration {}

class DriftIndexDeclaration implements DriftFileDeclaration, IndexDeclaration {
  @override
  final SourceRange declaration;

  @override
  final CreateIndexStatement node;

  DriftIndexDeclaration.fromNodeAndFile(this.node, FoundFile file)
      : declaration = SourceRange.fromNodeAndFile(node, file);
}

class CustomIndexDeclaration implements IndexDeclaration {
  const CustomIndexDeclaration();

  @override
  SourceRange get declaration {
    throw UnsupportedError('Custom declaration does not have a source');
  }
}
