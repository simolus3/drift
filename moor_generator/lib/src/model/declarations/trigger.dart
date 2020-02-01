part of 'declaration.dart';

abstract class TriggerDeclaration extends Declaration {}

class MoorTriggerDeclaration implements MoorDeclaration, TriggerDeclaration {
  @override
  final SourceRange declaration;

  @override
  final CreateTriggerStatement node;

  MoorTriggerDeclaration.fromNodeAndFile(this.node, FoundFile file)
      : declaration = SourceRange.fromNodeAndFile(node, file);
}
