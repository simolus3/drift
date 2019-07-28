part of '../ast.dart';

abstract class Statement extends AstNode {}

/// Marker mixin for statements that read from an existing table structure.
mixin CrudStatement on Statement {}

/// Marker mixin for statements that change the table structure.
mixin SchemaStatement on Statement {}
