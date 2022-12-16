/// Contains tools for [verifying migrations] that don't depend on `sqlparser`
/// and can thus be part of the core drift package.
///
/// [verifying migrations](https://drift.simonbinder.eu/docs/advanced-features/migrations/#verifying-migrations)
library drift.internal.migrations;

import 'package:drift/drift.dart';

/// A class that can create a [GeneratedDatabase] suitable for instantating an
/// older version of your app's database.
///
/// The implementation of this class is generated through the `drift_dev`
/// CLI tool.
/// Typically, you don't use this class directly but rather through the
/// `SchemaVerifier` class  part of `package:drift_dev/api/migrations.dart`
/// library.
abstract class SchemaInstantiationHelper {
  /// Creates a database with the state of an old schema [version] and using the
  /// given underlying [db] connection.
  GeneratedDatabase databaseForVersion(QueryExecutor db, int version);
}

/// Thrown by [SchemaInstantiationHelper.databaseForVersion] when trying to
/// instantiate a schema that hasn't been saved.
class MissingSchemaException implements Exception {
  /// The requested version that doesn't exist.
  final int requested;

  /// All known schema versions.
  final Iterable<int> available;

  /// A missing schema exception to be thrown when a requested schema snapshot
  /// is not available.
  const MissingSchemaException(this.requested, this.available);

  @override
  String toString() {
    return 'Unknown schema version $requested. '
        'Known are ${available.join(', ')}.';
  }
}
