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
abstract class HasWhereClause extends Statement {
  Expression get where;
}

/// Marker mixin for statements that change the table structure.
mixin SchemaStatement on Statement {}
