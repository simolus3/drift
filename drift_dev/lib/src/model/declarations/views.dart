part of 'declaration.dart';

abstract class ViewDeclaration extends Declaration {}

abstract class ViewDeclarationWithSql implements ViewDeclaration {
  /// The `CREATE VIEW` statement used to create this view.
  String get createSql;

  /// The parsed statement creating this view.
  CreateViewStatement get creatingStatement;
}

class DartViewDeclaration implements ViewDeclaration, DartDeclaration {
  @override
  final SourceRange declaration;

  @override
  final ClassElement element;

  final String dartQuerySource;
  final TableReferenceInDartView? primaryFrom;
  final List<TableReferenceInDartView> staticReferences;

  DartViewDeclaration(
    this.element,
    FoundFile file,
    this.primaryFrom,
    this.staticReferences,
    this.dartQuerySource,
  ) : declaration = SourceRange.fromElementAndFile(element, file);
}

class TableReferenceInDartView {
  final DriftTable table;
  final String name;

  TableReferenceInDartView(this.table, this.name);
}

class DriftViewDeclaration
    implements ViewDeclaration, DriftFileDeclaration, ViewDeclarationWithSql {
  @override
  final SourceRange declaration;

  @override
  final CreateViewStatement node;

  DriftViewDeclaration._(this.declaration, this.node);

  factory DriftViewDeclaration(CreateViewStatement node, FoundFile file) {
    return DriftViewDeclaration._(
      SourceRange.fromNodeAndFile(node, file),
      node,
    );
  }

  @override
  String get createSql => node.span!.text;

  @override
  CreateViewStatement get creatingStatement => node;
}
