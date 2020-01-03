part of '../query_builder.dart';

/// Some abstract schema entity that can be stored in a database. This includes
/// tables, triggers, views, indexes, etc.
abstract class DatabaseSchemaEntity {
  /// The (unalised) name of this entity in the database.
  String get entityName;
}

/// A sqlite trigger that's executed before, after or instead of a subset of
/// writes on a specific tables.
/// In moor, triggers can only be declared in `.moor` files.
///
/// For more information on triggers, see the [CREATE TRIGGER][sqlite-docs]
/// documentation from sqlite, or the [entry on sqlitetutorial.net][sql-tut].
///
/// [sqlite-docs]: https://sqlite.org/lang_createtrigger.html
/// [sql-tut]: https://www.sqlitetutorial.net/sqlite-trigger/
class Trigger extends DatabaseSchemaEntity {
  /// The `CREATE TRIGGER` sql statement that can be used to create this
  /// trigger.
  final String createTriggerStmt;
  @override
  final String entityName;

  /// Creates a trigger representation by the [createTriggerStmt] and its
  /// [entityName]. Mainly used by generated code.
  Trigger(this.createTriggerStmt, this.entityName);
}

/// A sqlite index on columns or expressions.
///
/// For more information on triggers, see the [CREATE TRIGGER][sqlite-docs]
/// documentation from sqlite, or the [entry on sqlitetutorial.net][sql-tut].
///
/// [sqlite-docs]: https://www.sqlite.org/lang_createindex.html
/// [sql-tut]: https://www.sqlitetutorial.net/sqlite-index/
class Index extends DatabaseSchemaEntity {
  @override
  final String entityName;

  /// The `CREATE INDEX` sql statement that can be used to create this index.
  final String createIndexStmt;

  /// Creates an index model by the [createIndexStmt] and its [entityName].
  /// Mainly used by generated code.
  Index(this.entityName, this.createIndexStmt);
}

/// An internal schema entity to run an sql statement when the database is
/// created.
///
/// The generator uses this entity to implement `@create` statements in moor
/// files:
/// ```sql
/// CREATE TABLE users (name TEXT);
///
/// @create: INSERT INTO users VALUES ('Bob');
/// ```
/// A [OnCreateQuery] is emitted for each `@create` statement in an included
/// moor file.
class OnCreateQuery extends DatabaseSchemaEntity {
  /// The sql statement that should be run in the default `onCreate` clause.
  final String sql;

  /// Create a query that will be run in the default `onCreate` migration.
  OnCreateQuery(this.sql);

  @override
  String get entityName => r'$internal$';
}
