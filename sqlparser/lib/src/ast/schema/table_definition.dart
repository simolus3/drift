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
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitForeignKeyClause(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [foreignTable, ...columnNames];

  @override
  bool contentEquals(ForeignKeyClause other) {
    return other.onDelete == onDelete && other.onUpdate == onUpdate;
  }
}

abstract class TableConstraint extends AstNode {
  final String name;

  TableConstraint(this.name);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitTableConstraint(this, arg);
  }

  @override
  bool contentEquals(TableConstraint other) {
    return other.name == name && _constraintEquals(other);
  }

  @visibleForOverriding
  bool _constraintEquals(covariant TableConstraint other);
}

class KeyClause extends TableConstraint {
  final bool isPrimaryKey;
  final List<Reference> indexedColumns;
  final ConflictClause onConflict;

  bool get isUnique => !isPrimaryKey;

  KeyClause(String name,
      {@required this.isPrimaryKey,
      @required this.indexedColumns,
      this.onConflict})
      : super(name);

  @override
  bool _constraintEquals(KeyClause other) {
    return other.isPrimaryKey == isPrimaryKey && other.onConflict == onConflict;
  }

  @override
  Iterable<AstNode> get childNodes => indexedColumns;
}

class CheckTable extends TableConstraint {
  final Expression expression;

  CheckTable(String name, this.expression) : super(name);

  @override
  bool _constraintEquals(CheckTable other) => true;

  @override
  Iterable<AstNode> get childNodes => [expression];
}

class ForeignKeyTableConstraint extends TableConstraint {
  final List<Reference> columns;
  final ForeignKeyClause clause;

  ForeignKeyTableConstraint(String name,
      {@required this.columns, @required this.clause})
      : super(name);

  @override
  bool _constraintEquals(ForeignKeyTableConstraint other) => true;

  @override
  Iterable<AstNode> get childNodes => [...columns, clause];
}
