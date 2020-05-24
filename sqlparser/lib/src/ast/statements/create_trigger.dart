part of '../ast.dart';

/// A "CREATE TRIGGER" statement, see https://sqlite.org/lang_createtrigger.html
class CreateTriggerStatement extends Statement implements CreatingStatement {
  final bool ifNotExists;
  final String triggerName;
  IdentifierToken triggerNameToken;

  final TriggerMode mode;
  final TriggerTarget target;

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
  }

  @override
  Iterable<AstNode> get childNodes sync* {
    if (target is UpdateTarget) yield* (target as UpdateTarget).columnNames;
    yield onTable;
    if (when != null) yield when;
    yield action;
  }

  @override
  bool contentEquals(CreateTriggerStatement other) {
    return other.ifNotExists == ifNotExists &&
        other.triggerName == triggerName &&
        other.mode == mode &&
        other.target == target;
  }
}

enum TriggerMode { before, after, insteadOf }

// todo: Should be an AstNode
abstract class TriggerTarget {
  const TriggerTarget._();
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(dynamic other) => other.runtimeType == runtimeType;

  /// Whether this target introduces the "new" table reference in the sub-scope
  /// of the create trigger statement.
  bool get introducesNew;

  /// Whether this target introduces the "old" table reference in the sub-scope
  /// of the create trigger statement.
  bool get introducesOld;
}

class DeleteTarget extends TriggerTarget {
  const DeleteTarget() : super._();

  @override
  bool get introducesNew => false;
  @override
  bool get introducesOld => true;
}

class InsertTarget extends TriggerTarget {
  const InsertTarget() : super._();

  @override
  bool get introducesNew => true;
  @override
  bool get introducesOld => false;
}

class UpdateTarget extends TriggerTarget {
  final List<Reference> columnNames;

  UpdateTarget(this.columnNames) : super._();

  @override
  bool get introducesNew => true;
  @override
  bool get introducesOld => true;
}
