import 'entities.dart';

/// The resolved static schema of a drift database.
///
/// This contains all tables, views, triggers, indexes and other drift-
/// specific entities that are also encoded as schema entities.
extension type const DatabaseSchema(List<DatabaseSchemaEntity> entities)
    implements Iterable<DatabaseSchemaEntity> {
  /// An empty schema with no tables.
  static const DatabaseSchema empty = DatabaseSchema([]);
}
