part of '../ast.dart';

enum ReferenceAction { setNull, setDefault, cascade, restrict, noAction }

class ForeignKeyClause extends AstNode {
  final TableReference foreignTable;
  final List<Reference> columnNames;
  final ReferenceAction onDelete;
  final ReferenceAction onUpdate;

  ForeignKeyClause(
      {@required this.foreignTable,
      @required this.columnNames,
      this.onDelete,
      this.onUpdate});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitForeignKeyClause(this);

  @override
  Iterable<AstNode> get childNodes => [foreignTable, ...columnNames];

  @override
  bool contentEquals(ForeignKeyClause other) {
    return other.onDelete == onDelete && other.onUpdate == onUpdate;
  }
}
