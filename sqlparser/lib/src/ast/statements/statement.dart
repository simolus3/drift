part of '../ast.dart';

abstract class Statement extends AstNode {
  Token? semicolon;
}

/// A statement that reads from an existing table structure and has an optional
/// `WITH` clause.
abstract class CrudStatement extends Statement {
  WithClause? withClause;

  CrudStatement._(this.withClause);
}

/// Interfaces for statements that have a primary source table on which they
/// operate.
/// This includes delete, update and insert statements. It also includes the
/// common [SelectStatement], but not compound select statements or `VALUES`
/// statements.
abstract class HasPrimarySource extends Statement {
  /// The primary table this statement operates on. This is the part after the
  /// `FROM` for select and delete statements, the part after the `INTO` for
  /// inserts and the name after the `UPDATE` for updates.
  Queryable? get table;
}

/// Interfaces for statements that have a `FROM` clause.
///
/// This includes selects and, since recently, updates.
abstract class HasFrom extends Statement {
  /// The table, join clause or subquery appearing in the `FROM` clause.
  Queryable? get from;
}

/// Interface for statements that have a primary where clause (select, update,
/// delete).
abstract class StatementWithWhere extends Statement implements HasWhereClause {}

/// Marker interface for statements that change the table structure.
abstract class SchemaStatement extends Statement implements PartOfMoorFile {}

/// Marker interface for schema statements that create a schematic entity.
abstract class CreatingStatement extends SchemaStatement {
  String get createdName;
}
