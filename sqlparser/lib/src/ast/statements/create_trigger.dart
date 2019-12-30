part of '../ast.dart';

/// A "CREATE TRIGGER" statement, see https://sqlite.org/lang_createtrigger.html
class CreateTriggerStatement extends Statement implements SchemaStatement {
  final bool ifNotExists;
  final String triggerName;
  IdentifierToken triggerNameToken;

  final TriggerMode mode;
  final TriggerTarget target;

  final TableReference onTable;

  final Expression when;
  final Block action;

  CreateTriggerStatement(
      {this.ifNotExists = false,
      @required this.triggerName,
      @required this.mode,
      @required this.target,
      @required this.onTable,
      this.when,
      @required this.action});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateTriggerStatement(this, arg);
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

abstract class TriggerTarget {
  const TriggerTarget();
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(dynamic other) => other.runtimeType == runtimeType;
}

class DeleteTarget extends TriggerTarget {
  const DeleteTarget();
}

class InsertTarget extends TriggerTarget {
  const InsertTarget();
}

class UpdateTarget extends TriggerTarget {
  final List<Reference> columnNames;

  UpdateTarget(this.columnNames);
}
