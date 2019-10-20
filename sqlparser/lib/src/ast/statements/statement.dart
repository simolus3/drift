part of '../ast.dart';

abstract class Statement extends AstNode {
  Token semicolon;
}

/// Marker mixin for statements that read from an existing table structure.
mixin CrudStatement on Statement {}

/// Interface for statements that have a primary where clause (select, update,
/// delete).
abstract class HasWhereClause extends Statement {
  Expression get where;
}

/// Marker mixin for statements that change the table structure.
mixin SchemaStatement on Statement implements PartOfMoorFile {}
