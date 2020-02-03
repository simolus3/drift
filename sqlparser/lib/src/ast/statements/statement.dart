part of '../ast.dart';

abstract class Statement extends AstNode {
  Token semicolon;
}

/// A statement that reads from an existing table structure and has an optional
/// `WITH` clause.
abstract class CrudStatement extends Statement {
  WithClause withClause;

  CrudStatement._(this.withClause);
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
