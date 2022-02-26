import 'package:meta/meta.dart';

import '../../analysis/analysis.dart';
import '../../reader/tokenizer/token.dart';
import '../ast.dart'; // todo: Remove this import

abstract class Statement extends AstNode {
  Token? semicolon;
}

/// A statement that reads from an existing table structure and has an optional
/// `WITH` clause.
abstract class CrudStatement extends Statement {
  WithClause? withClause;

  @internal
  CrudStatement(this.withClause);
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

/// Interface for statements that can return columns after writing data.
///
/// Columns are returned with a `RETURNING` clause (see [Returning]). After
/// analyzing a node, statements with a [returning] clause will have their
/// [returnedResultSet] set to the resolved columns.
abstract class StatementReturningColumns extends Statement {
  /// The returning clause of this statement, if there is any.
  Returning? get returning;

  /// The result set of the [returning] clause.
  ResultSet? returnedResultSet;
}

/// Marker interface for statements that change the table structure.
abstract class SchemaStatement extends Statement implements PartOfDriftFile {}

/// Marker interface for schema statements that create a schematic entity.
abstract class CreatingStatement extends SchemaStatement {
  String get createdName;
}
