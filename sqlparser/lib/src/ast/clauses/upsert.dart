part of '../ast.dart';

class UpsertClause extends AstNode implements HasWhereClause {
  final List<IndexedColumn> /*?*/ onColumns;
  @override
  final Expression where;

  final UpsertAction action;

  UpsertClause({this.onColumns, this.where, @required this.action});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitUpsertClause(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes {
    return [
      if (onColumns != null) ...onColumns,
      if (where != null) where,
      action,
    ];
  }

  @override
  bool contentEquals(UpsertClause other) => true;
}

abstract class UpsertAction extends AstNode {}

class DoNothing extends UpsertAction {
  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDoNothing(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool contentEquals(DoNothing other) => true;
}

class DoUpdate extends UpsertAction implements HasWhereClause {
  final List<SetComponent> set;
  @override
  final Expression where;

  DoUpdate(this.set, {this.where});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDoUpdate(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [...set, if (where != null) where];

  @override
  bool contentEquals(DoUpdate other) => true;
}
