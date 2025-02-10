/// Some abstract schema entity that can be stored in a database. This includes
/// tables, triggers, views, indexes, etc.
abstract interface class DatabaseSchemaEntity {
  /// The (unalised) name of this entity in the database.
  String get entityName;
}
