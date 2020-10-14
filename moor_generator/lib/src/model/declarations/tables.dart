part of 'declaration.dart';

abstract class TableDeclaration extends Declaration {
  /// Whether this declaration declares a virtual table.
  bool get isVirtual;
}

abstract class TableDeclarationWithSql implements TableDeclaration {
  /// The `CREATE TABLE` statement used to create this table.
  String get createSql;
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

class MoorTableDeclaration
    implements TableDeclaration, MoorDeclaration, TableDeclarationWithSql {
  @override
  final SourceRange declaration;

  @override
  final TableInducingStatement node;

  @override
  bool get isVirtual => node is CreateVirtualTableStatement;

  @override
  String get createSql => node.span.text;

  MoorTableDeclaration._(this.declaration, this.node);

  factory MoorTableDeclaration(TableInducingStatement node, FoundFile file) {
    return MoorTableDeclaration._(
      SourceRange.fromNodeAndFile(node, file),
      node,
    );
  }
}

class CustomVirtualTableDeclaration implements TableDeclarationWithSql {
  @override
  final String createSql;

  CustomVirtualTableDeclaration(this.createSql);

  @override
  SourceRange get declaration {
    throw UnsupportedError('Custom declaration does not have a source');
  }

  @override
  bool get isVirtual => true;
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
