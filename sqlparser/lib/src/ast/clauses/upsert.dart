import '../ast.dart'; // todo: Remove this import
import '../node.dart';
import '../statements/create_index.dart' show IndexedColumn;

class UpsertClause extends AstNode {
  final List<UpsertClauseEntry> entries;

  UpsertClause(this.entries);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitUpsertClause(this, arg);
  }

  @override
  List<UpsertClauseEntry> get childNodes => entries;

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(entries, this, arg);
  }
}

class UpsertClauseEntry extends AstNode implements HasWhereClause {
  final List<IndexedColumn>? onColumns;
  @override
  Expression? where;

  UpsertAction action;

  UpsertClauseEntry({this.onColumns, this.where, required this.action});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitUpsertClauseEntry(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(onColumns!, this, arg);
    where = transformer.transformNullableChild(where, this, arg);
    action = transformer.transformChild(action, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes {
    return [
      if (onColumns != null) ...onColumns!,
      if (where != null) where!,
      action,
    ];
  }
}

abstract class UpsertAction extends AstNode {}

class DoNothing extends UpsertAction {
  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDoNothing(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  Iterable<AstNode> get childNodes => const [];
}

class DoUpdate extends UpsertAction implements HasWhereClause {
  final List<SetComponent> set;
  @override
  Expression? where;

  DoUpdate(this.set, {this.where});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDoUpdate(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(set, this, arg);
    where = transformer.transformNullableChild(where, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [...set, if (where != null) where!];
}
