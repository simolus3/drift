import 'package:moor/moor.dart';

import 'package:moor_generator/src/services/schema/verifier_impl.dart';

abstract class SchemaVerifier {
  factory SchemaVerifier(SchemaInstantiationHelper helper) =
      VerifierImplementation;

  /// Creates a [DatabaseConnection] that contains empty tables created for the
  /// known schema [version].
  ///
  /// This is useful as a starting point for a schema migration test. You can
  /// use the [DatabaseConnection] returned to create an instance of your
  /// application database, which can then be migrated through
  /// [migrateAndValidate].
  Future<DatabaseConnection> startAt(int version);

  /// Runs a schema migration and verifies that it transforms the database into
  /// a correct state.
  ///
  /// This involves opening the [db] and calling its
  /// [GeneratedDatabase.migration] to migrate it to the latest version.
  /// Finally, the method will read from `sqlite_schema` to verify that the
  /// schema at runtime matches the expected schema version.
  ///
  /// If [validateDropped] is enabled (defaults to `false`), the method also
  /// validates that no further tables, triggers or views apart from those
  /// expected exist.
  Future<void> migrateAndValidate(GeneratedDatabase db, int expectedVersion,
      {bool validateDropped = false});
}

/// The implementation of this class is generated through the `moor_generator`
/// CLI tool.
abstract class SchemaInstantiationHelper {
  GeneratedDatabase databaseForVersion(QueryExecutor db, int version);
}

/// Thrown when trying to instantiate a schema that hasn't been saved.
class MissingSchemaException implements Exception {
  /// The requested version that doesn't exist.
  final int requested;

  /// All known schema versions.
  final Iterable<int> available;

  MissingSchemaException(this.requested, this.available);

  @override
  String toString() {
    return 'Unknown schema version $requested. '
        'Known are ${available.join(', ')}.';
  }
}

/// Thrown when the actual schema differs from the expected schema.
class SchemaMismatch implements Exception {
  final String explanation;

  SchemaMismatch(this.explanation);

  @override
  String toString() {
    return 'Schema does not match\n$explanation';
  }
}
