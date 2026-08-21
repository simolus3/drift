import 'package:drift3_preview/drift.dart';
// ignore: implementation_imports
import 'package:drift/src/drift3_preview/src/database/db_base.dart';
import 'package:sqlite3/common.dart';

import '../connection/connection.dart';
import '../dialect/dialect.dart';
import 'common.dart';
import 'find_differences.dart';

/// A helper, primarily meant for unit tests, to verify that database migrations
/// on drift databases migrate them towards expected schemas.
///
/// For more information on how to use this class, see
/// [migration tests](https://drift.simonbinder.eu/migrations/tests/).
final class SchemaVerifier {
  /// The dialect to use when opening new connections.
  ///
  /// Defaults to the default [SqliteDialect].
  final DriftDialectFactory dialect;

  /// Helper responsible for instantiating reference schemas as a starting point
  /// for migrations (and a final comparison).
  final SchemaInstantiationHelper helper;

  /// Function responsible for opening new in-memory SQLite database connections
  /// used to test migrations with.
  CommonDatabase Function() openDatabase;

  /// @nodoc
  SchemaVerifier({
    required this.helper,
    required this.openDatabase,
    this.dialect = SqliteDialect.new,
  });

  /// Creates a [DriftConnection] that contains empty tables created for the
  /// known schema [version].
  ///
  /// This is useful as a starting point for a schema migration test. You can
  /// use the [DriftConnection] returned to create an instance of your
  /// application database, which can then be migrated through
  /// [migrateAndValidate].
  ///
  /// If you want to insert data in a migration test, use [schemaAt].
  Future<DriftConnection> startAt(int version) async {
    final schema = await schemaAt(version);
    return schema.newConnection();
  }

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
  Future<InitializedSchema> schemaAt(int version) async {
    final rawDb = openDatabase();
    final uninitialized = InitializedSchema._(rawDb, dialect);

    final db = helper.databaseForVersion(
      uninitialized.newConnection(),
      version,
    );

    // Opening the helper database will instantiate the schema for us
    await db.initialize();
    await db.close();

    return uninitialized;
  }

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
  /// The [ValidationOptions] can be used to make the schema validation more
  /// strict (e.g. by enabling [ValidationOptions.validateDropped] to ensure
  /// that no old tables continue to exist if they're not referenced in the new
  /// schema) or more lenient (e.g. by disabling
  /// [ValidationOptions.validateColumnConstraints]).
  Future<void> migrateAndValidate(
    GeneratedDatabase db,
    int expectedVersion, {
    ValidationOptions options = const ValidationOptions(),
  }) async {
    // Open a connection to instantiate and extract the reference schema.
    final connection = await schemaAt(expectedVersion);
    final referenceSchema = SyntacticSchema.readFromDatabase(
      connection.rawDatabase,
    );

    // Attach the reference schema to the database so that VerifySelf.validateDatabaseSchema
    // works
    expectedSchema[db] = referenceSchema;

    // Run migrations from the old version to the new version.
    await db.runMigrations(null, expectedVersion);
    final actualSchema = SyntacticSchema.readFromDatabase(
      connection.rawDatabase,
    );

    verify(
      referenceSchema: referenceSchema,
      actualSchema: actualSchema,
      options: options,
    );
  }

  /// Utility function used by generated tests to verify that migrations
  /// modify the database schema as expected.
  ///
  /// Foreign key constraints are disabled for this operation.
  Future<void> testWithDataIntegrity<
    OldDatabase extends GeneratedDatabase,
    NewDatabase extends GeneratedDatabase
  >({
    required OldDatabase Function(DriftConnection) createOld,
    required NewDatabase Function(DriftConnection) createNew,
    required GeneratedDatabase Function(DriftConnection) openTestedDatabase,
    required void Function(Batch, OldDatabase) createItems,
    required Future<void> Function(NewDatabase) validateItems,
    required int oldVersion,
    required int newVersion,
    ValidationOptions options = const ValidationOptions(),
  }) async {
    final schema = await schemaAt(oldVersion);

    final oldDb = createOld(schema.newConnection());
    await oldDb.batch((batch) => createItems(batch, oldDb));
    await oldDb.close();

    final db = openTestedDatabase(schema.newConnection());
    await migrateAndValidate(db, newVersion, options: options);
    await db.close();

    final newDb = createNew(schema.newConnection());
    await validateItems(newDb);
    await newDb.close();
  }
}

/// Contains an initialized schema with all tables, views, triggers and indices.
///
/// You can use the [newConnection] for your database class and the
/// [rawDatabase] to insert data before the migration.
final class InitializedSchema {
  /// The raw database from the `sqlite3` package.
  ///
  /// The database contains all tables, views, triggers and indices from the
  /// requested schema. It can be used to insert data before a migration to
  /// verify that it's still intact after the migration.
  ///
  /// This database backs the [newConnection], so it's not necessary to close it
  /// if you're attaching a database later.
  final CommonDatabase rawDatabase;

  final DriftDialectFactory _dialect;

  InitializedSchema._(this.rawDatabase, this._dialect);

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
  DriftConnection newConnection() {
    return DriftConnection(
      dialect: _dialect,
      openConnection: () async =>
          SqliteConnection(rawDatabase, closeUnderlyingWhenClosed: false),
    );
  }

  /// [CommonDatabase.close]s the underlying [rawDatabase] backing the initial
  /// schema.
  ///
  /// Not calling this method technically leaks resources, but [rawDatabase] is
  /// an in-memory database that also has finalizers closing it when it's not
  /// used anymore. Further, unit tests are typically short-lived processes, so
  /// forgetting to call [close] does not have terrible side-effects.
  void close() => rawDatabase.close();
}

/// A class that can create a [GeneratedDatabase] suitable for instantating an
/// older version of your app's database.
///
/// The implementation of this class is generated through the `drift_dev`
/// CLI tool.
/// Typically, you don't use this class directly but rather through the
/// `SchemaVerifier` class  part of `package:drift_dev/api/migrations_native.dart`
/// (or it's web pendant) library.
abstract interface class SchemaInstantiationHelper {
  /// Creates a database with the state of an old schema [version] and using the
  /// given underlying [db] connection.
  GeneratedDatabase databaseForVersion(DriftConnection db, int version);
}

/// Thrown by [SchemaInstantiationHelper.databaseForVersion] when trying to
/// instantiate a schema that hasn't been saved.
final class MissingSchemaException implements Exception {
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
