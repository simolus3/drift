part of 'declaration.dart';

abstract class TableDeclaration extends Declaration {
  /// Whether this declaration declares a virtual table.
  bool get isVirtual;
}

abstract class TableDeclarationWithSql implements TableDeclaration {
  /// The `CREATE TABLE` statement used to create this table.
  String get createSql;

  /// The parsed statement creating this table.
  TableInducingStatement get creatingStatement;
}

class DartTableDeclaration implements TableDeclaration, DartDeclaration {
  @override
  final SourceRange declaration;

  @override
  final ClassElement element;

  @override
  bool get isVirtual => false;

  DartTableDeclaration._(this.declaration, this.element);

  factory DartTableDeclaration(ClassElement element, FoundFile file) {
    return DartTableDeclaration._(
      SourceRange.fromElementAndFile(element, file),
      element,
    );
  }
}

class DriftTableDeclaration
    implements TableDeclaration, DriftFileDeclaration, TableDeclarationWithSql {
  @override
  final SourceRange declaration;

  @override
  final TableInducingStatement node;

  DriftTableDeclaration._(this.declaration, this.node);

  factory DriftTableDeclaration(TableInducingStatement node, FoundFile file) {
    return DriftTableDeclaration._(
      SourceRange.fromNodeAndFile(node, file),
      node,
    );
  }

  @override
  bool get isVirtual => node is CreateVirtualTableStatement;

  @override
  String get createSql => node.span!.text;

  @override
  TableInducingStatement get creatingStatement => node;
}

class CustomVirtualTableDeclaration implements TableDeclarationWithSql {
  @override
  final CreateVirtualTableStatement creatingStatement;

  CustomVirtualTableDeclaration(this.creatingStatement);

  @override
  SourceRange get declaration {
    throw UnsupportedError('Custom declaration does not have a source');
  }

  @override
  bool get isVirtual => true;

  @override
  String get createSql => creatingStatement.span!.text;
}

class CustomTableDeclaration implements TableDeclaration {
  const CustomTableDeclaration();

  @override
  SourceRange get declaration {
    throw UnsupportedError('Custom declaration does not have a source');
  }

  @override
  bool get isVirtual => false;
}
