import '../../reader/tokenizer/token.dart';
import '../ast.dart';

/// An `ALTER TABLE` statement in SQLite.
final class AlterTableStatement extends Statement {
  TableReference table;
  AlterTableInstruction instruction;

  AlterTableStatement(this.table, this.instruction);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitAlterTableStatement(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [table, instruction];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    table = transformer.transformChild(table, this, arg);
    instruction = transformer.transformChild(instruction, this, arg);
  }
}

/// An instruction to run as part of an [AlterTableStatement].
sealed class AlterTableInstruction extends AstNode {}

final class RenameTo extends AlterTableInstruction {
  String newTableName;
  Token? newTableNameToken;

  RenameTo(this.newTableName);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitRenameTo(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

final class RenameColumnTo extends AlterTableInstruction {
  Reference oldName;
  String newName;
  Token? newNameToken;

  RenameColumnTo(this.oldName, this.newName);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitRenameColumnTo(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [oldName];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    oldName = transformer.transformChild(oldName, this, arg);
  }
}

final class AddColumn extends AlterTableInstruction {
  ColumnDefinition definition;

  AddColumn(this.definition);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitAddColumn(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [definition];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    definition = transformer.transformChild(definition, this, arg);
  }
}

final class DropColumn extends AlterTableInstruction {
  Reference column;

  DropColumn(this.column);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDropColumn(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [column];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    column = transformer.transformChild(column, this, arg);
  }
}

/// An `ALTER TABLE tbl ALTER COLUMN col` statement added in SQLite version
/// 3.53.0.
final class AlterColumn extends AlterTableInstruction {
  String columnName;
  IdentifierToken? columnNameToken;
  AlterColumnInstruction instruction;

  AlterColumn({required this.columnName, required this.instruction});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitAlterColumn(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [instruction];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    instruction = transformer.transformChild(instruction, this, arg);
  }
}

/// An `ALTER TABLE ADD CONSTRAINT` statement added in SQLite version 3.53.0.
final class AddConstraint extends AlterTableInstruction {
  CheckTable checkTable;

  AddConstraint({required this.checkTable});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitAddConstraint(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [checkTable];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    checkTable = transformer.transformChild(checkTable, this, arg);
  }
}

/// An `ALTER TABLE Drop CONSTRAINT` statement added in SQLite version 3.53.0.
final class DropConstraint extends AlterTableInstruction {
  final String name;

  DropConstraint({required this.name});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDropConstraint(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

/// An instruction that appears in an [AlterColumn] instruction.
sealed class AlterColumnInstruction extends AstNode {}

/// An `ALTER COLUMN SET NOT NULL` instruction.
final class AlterColumnSetNotNull extends AlterColumnInstruction {
  ConflictClause? onConflict;

  AlterColumnSetNotNull({this.onConflict});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitAlterColumnSetNotNull(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

/// An `ALTER COLUMN DROP NOT NULL` instruction.
final class AlterColumnDropNotNull extends AlterColumnInstruction {
  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitAlterColumnDropNotNull(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}
