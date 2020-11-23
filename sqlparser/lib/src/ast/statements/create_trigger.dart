part of '../ast.dart';

/// A "CREATE TRIGGER" statement, see https://sqlite.org/lang_createtrigger.html
class CreateTriggerStatement extends Statement implements CreatingStatement {
  final bool ifNotExists;
  final String triggerName;
  IdentifierToken triggerNameToken;

  final TriggerMode mode;
  TriggerTarget target;

  TableReference onTable;

  Expression when;
  Block action;

  CreateTriggerStatement(
      {this.ifNotExists = false,
      @required this.triggerName,
      @required this.mode,
      @required this.target,
      @required this.onTable,
      this.when,
      @required this.action});

  @override
  String get createdName => triggerName;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateTriggerStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    onTable = transformer.transformChild(onTable, this, arg);
    when = transformer.transformNullableChild(when, this, arg);
    action = transformer.transformChild(action, this, arg);
    target = transformer.transformChild(target, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [
        target,
        onTable,
        if (when != null) when,
        action,
      ];
}

enum TriggerMode { before, after, insteadOf }

abstract class TriggerTarget extends AstNode {
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(dynamic other) => other.runtimeType == runtimeType;

  @override
  Iterable<AstNode> get childNodes => const Iterable.empty();

  /// Whether this target introduces the "new" table reference in the sub-scope
  /// of the create trigger statement.
  bool get introducesNew;

  /// Whether this target introduces the "old" table reference in the sub-scope
  /// of the create trigger statement.
  bool get introducesOld;
}

class DeleteTarget extends TriggerTarget {
  Token deleteToken;

  @override
  bool get introducesNew => false;
  @override
  bool get introducesOld => true;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDeleteTriggerTarget(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

class InsertTarget extends TriggerTarget {
  Token insertToken;

  @override
  bool get introducesNew => true;
  @override
  bool get introducesOld => false;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitInsertTriggerTarget(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

class UpdateTarget extends TriggerTarget {
  Token updateToken;
  final List<Reference> columnNames;

  UpdateTarget(this.columnNames);

  @override
  bool get introducesNew => true;
  @override
  bool get introducesOld => true;

  @override
  Iterable<AstNode> get childNodes => columnNames;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitUpdateTriggerTarget(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(columnNames, this, arg);
  }
}
