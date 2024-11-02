import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart';

import 'package:drift_dev/src/services/schema/verifier_common.dart';

export 'package:drift_dev/src/services/schema/verifier_common.dart'
    show SchemaMismatch;
export 'package:drift/internal/migrations.dart'
    show SchemaInstantiationHelper, MissingSchemaException;

abstract class SchemaVerifier<DB extends CommonDatabase> {
  /// Creates a [DatabaseConnection] that contains empty tables created for the
  /// known schema [version].
  ///
  /// This is useful as a starting point for a schema migration test. You can
  /// use the [DatabaseConnection] returned to create an instance of your
  /// application database, which can then be migrated through
  /// [migrateAndValidate].
  ///
  /// If you want to insert data in a migration test, use [schemaAt].
  Future<DatabaseConnection> startAt(int version);

  /// Creates a new database and instantiates the schema with the given
  /// [version].
  ///
  /// This can be used as a starting point for a complex schema migration test
  /// to verify data integrity. You can roughly follow these steps to write such
  /// tests:
  ///
  ///  - call [schemaAt] with the starting version you want to test
  ///  - use the [InitializedSchema.rawDatabase] of the returned
  ///   [InitializedSchema] to insert data.
  ///  - connect your database class to a [InitializedSchema.newConnection]
  ///  - call [migrateAndValidate] with the database and your target schema
  ///    version to run a migration and verify that it yields the desired schema
  ///    when done.
  ///  - run select statements on your database to verify that the data from
  ///    step 2 hasn't been affected by the migration.
  ///
  /// If you only want to verify the schema without data, using [startAt] might
  /// be easier.
  Future<InitializedSchema<DB>> schemaAt(int version);

  /// Runs a schema migration and verifies that it transforms the database into
  /// a correct state.
  ///
  /// This involves opening the [db] and calling its
  /// [GeneratedDatabase.migration] to migrate it to the latest version.
  /// Finally, the method will read from `sqlite_schema` to verify that the
  /// schema at runtime matches the expected schema version.
  ///
  /// The future completes normally if the schema migration succeeds and brings
  /// the database into the expected schema. If the comparison fails, a
  /// [SchemaMismatch] exception will be thrown.
  ///
  /// If [validateDropped] is enabled (defaults to `false`), the method also
  /// validates that no further tables, triggers or views apart from those
  /// expected exist.
  Future<void> migrateAndValidate(GeneratedDatabase db, int expectedVersion,
      {bool validateDropped = false});

  /// Utility function used by generated tests to verify that migrations
  /// modify the database schema as expected.
  ///
  /// Foreign key constraints are disabled for this operation.
  Future<void> testWithDataIntegrity<OldDatabase extends GeneratedDatabase,
      NewDatabase extends GeneratedDatabase>({
    required OldDatabase Function(QueryExecutor) createOld,
    required NewDatabase Function(QueryExecutor) createNew,
    required GeneratedDatabase Function(QueryExecutor) openTestedDatabase,
    required void Function(Batch, OldDatabase) createItems,
    required Future Function(NewDatabase) validateItems,
    required int oldVersion,
    required int newVersion,
  });
}

/// Contains an initialized schema with all tables, views, triggers and indices.
///
/// You can use the [newConnection] for your database class and the
/// [rawDatabase] to insert data before the migration.
class InitializedSchema<DB extends CommonDatabase> {
  /// The raw database from the `sqlite3` package.
  ///
  /// The database contains all tables, views, triggers and indices from the
  /// requested schema. It can be used to insert data before a migration to
  /// verify that it's still intact after the migration.
  ///
  /// This database backs the [newConnection], so it's not necessary to close it
  /// if you're attaching a database later.
  final DB rawDatabase;

  final DatabaseConnection Function() _createConnection;

  /// A database connection with a prepared schema.
  ///
  /// You can connect your database classes to this as a starting point for
  /// migration tests.
  @Deprecated('Use newConnection instead, and store the result')
  late final DatabaseConnection connection = _createConnection();

  @internal
  InitializedSchema(this.rawDatabase, this._createConnection);

  /// Creates a new database connection.
  ///
  /// All connections returned by this method point to the [rawDatabase].
  /// However, each call to [newConnection] returns an independent connection
  /// that is considered closed from drift's point of view. This means that the
  /// [rawDatabase] can be used by multiple generated database classes that
  /// can independently be opened and closed, albeit not simultaneously.
  ///
  /// ## Example
  ///
  /// When generating the schema helpers with the `--data-classes` and the
  /// `--companions` command-line flags, this method can be used to create drift
  /// databases inserting data at specific versions:
  ///
  /// ```dart
  /// import 'generated/schema.dart';
  /// import 'generated/schema_v1.dart' as v1;
  /// import 'generated/schema_v2.dart' as v2;
  ///
  /// test('data integrity from v1 to v2', () async {
  ///   final verifier = SchemaVerifier(GeneratedHelper());
  ///   final schema = await verifier.schemaAt(1);
  ///
  ///   // Insert some data from the view of the old database on an independent
  ///   // connection!
  ///   final oldDb = v1.DatabaseAtV1(schema.newConnection());
  ///   await oldDb.into(oldDb.users).insert(v1.UsersCompanion(id: Value(1)));
  ///   await oldDb.close();
  ///
  ///   // Run the migration on the real database class from your app
  ///   final dbForMigration = Database(schema.newConnection());
  ///   await verifier.migrateAndValidate(dbForMigration, 2);
  ///   await dbForMigration.close();
  ///
  ///   // Make sure the user is still here with a new database at v2
  ///   final checkDb = v2.DatabaseAtV2(schema.newConnection());
  ///   final user = await checkDb.select(checkDb.users).getSingle();
  ///   expect(user.id, 1);
  ///   expect(user.name, 'default name from migration');
  ///   await checkDb.close();
  /// });
  /// ```
  DatabaseConnection newConnection() => _createConnection();
}
