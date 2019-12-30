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
/// documentation from sqlite, or the [entry on sqlitetutorial.net][sql-tutorial].
///
/// [sqlite-docs]: (https://sqlite.org/lang_createtrigger.html)
/// [sql-tutorial]: (https://www.sqlitetutorial.net/sqlite-trigger/)
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
