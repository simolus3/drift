part of '../ast.dart';

enum ReferenceAction { setNull, setDefault, cascade, restrict, noAction }

class ForeignKeyClause extends AstNode {
  TableReference foreignTable;
  List<Reference> columnNames;
  final ReferenceAction? onDelete;
  final ReferenceAction? onUpdate;
  DeferrableClause? deferrable;

  ForeignKeyClause({
    required this.foreignTable,
    required this.columnNames,
    this.onDelete,
    this.onUpdate,
    this.deferrable,
  });

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitForeignKeyClause(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    foreignTable = transformer.transformChild(foreignTable, this, arg);
    columnNames = transformer.transformChildren(columnNames, this, arg);
    deferrable = transformer.transformChild(deferrable!, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [
        foreignTable,
        ...columnNames,
        if (deferrable != null) deferrable!,
      ];

  InitialDeferrableMode get effectiveDeferrableMode {
    return deferrable?.effectiveInitialMode ?? InitialDeferrableMode.immediate;
  }
}

enum InitialDeferrableMode {
  deferred,
  immediate,
}

class DeferrableClause extends AstNode {
  final bool not;
  final InitialDeferrableMode? declaredInitially;

  DeferrableClause(this.not, this.declaredInitially);

  InitialDeferrableMode? get effectiveInitialMode {
    if (not || declaredInitially == null) {
      return InitialDeferrableMode.immediate;
    }

    return declaredInitially;
  }

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDeferrableClause(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const Iterable.empty();

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

abstract class TableConstraint extends AstNode {
  final String? name;
  Token? nameToken;

  TableConstraint(this.name);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitTableConstraint(this, arg);
  }

  bool constraintEquals(covariant TableConstraint other);
}

class KeyClause extends TableConstraint {
  final bool isPrimaryKey;
  List<IndexedColumn> columns;
  final ConflictClause? onConflict;

  bool get isUnique => !isPrimaryKey;

  @Deprecated('Use columns instead')
  List<Reference> get indexedColumns {
    return [
      for (final column in columns)
        if (column.expression is Reference) column.expression as Reference
    ];
  }

  KeyClause(super.name,
      {required this.isPrimaryKey, required this.columns, this.onConflict});

  @override
  bool constraintEquals(KeyClause other) {
    return other.isPrimaryKey == isPrimaryKey && other.onConflict == onConflict;
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    columns = transformer.transformChildren(columns, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => columns;
}

class CheckTable extends TableConstraint {
  Expression expression;

  CheckTable(super.name, this.expression);

  @override
  bool constraintEquals(CheckTable other) => true;

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    expression = transformer.transformChild(expression, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [expression];
}

class ForeignKeyTableConstraint extends TableConstraint {
  List<Reference> columns;
  ForeignKeyClause clause;

  ForeignKeyTableConstraint(super.name,
      {required this.columns, required this.clause});

  @override
  bool constraintEquals(ForeignKeyTableConstraint other) => true;

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    columns = transformer.transformChildren(columns, this, arg);
    clause = transformer.transformChild(clause, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [...columns, clause];
}
