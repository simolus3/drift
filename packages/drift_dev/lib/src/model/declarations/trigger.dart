part of 'declaration.dart';

abstract class TriggerDeclaration extends Declaration {
  /// The sql statement to create the modelled trigger.
  String get createSql;
}

class MoorTriggerDeclaration implements MoorDeclaration, TriggerDeclaration {
  @override
  final SourceRange declaration;

  @override
  final CreateTriggerStatement node;

  MoorTriggerDeclaration.fromNodeAndFile(this.node, FoundFile file)
      : declaration = SourceRange.fromNodeAndFile(node, file);

  @override
  String get createSql => node.span!.text;
}

class CustomTriggerDeclaration extends TriggerDeclaration {
  @override
  final String createSql;

  @override
  SourceRange get declaration {
    throw StateError('Custom declaration does not have a range');
  }

  CustomTriggerDeclaration(this.createSql);
}
