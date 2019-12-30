/// Some schema entity found.
///
/// Most commonly a table, but it can also be a trigger.
abstract class MoorSchemaEntity {
  /// All entities that have to be created before this entity can be created.
  ///
  /// For tables, this can be contents of a `REFERENCES` clause. For triggers,
  /// it would be the tables watched.
  ///
  /// The generator will verify that the graph of entities and [references]
  /// is acyclic and sort them topologically.
  Iterable<MoorSchemaEntity> get references;

  /// A human readable name of this entity, like the table name.
  String get displayName;
}
