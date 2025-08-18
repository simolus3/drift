import 'package:drift/drift.dart';
import 'package:drift/internal/migrations.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:drift_dev/src/services/schema/verifier_native.dart';
import 'package:drift_dev/src/services/schema/verifier_common.dart';

import 'migrations_common.dart' as common;

export 'migrations_common.dart'
    show SchemaMismatch, SchemaInstantiationHelper, MissingSchemaException;

abstract class SchemaVerifier implements common.SchemaVerifier<Database> {
  /// Creates a schema verifier for the drift-generated [helper].
  ///
  /// See [tests] for more information.
  /// The optional [setup] parameter is used internally by the verifier for
  /// every database connection it opens. This can be used to, for instance,
  /// register custom functions expected by your database.
  ///
  /// [tests]: https://drift.simonbinder.eu/docs/migrations/tests/
  factory SchemaVerifier(
    SchemaInstantiationHelper helper, {
    void Function(Database raw)? setup,
  }) = NativeSchemaVerifier;
}

/// Utilities verifying that the current schema of the database matches what
/// the generated code expects.
extension VerifySelf on GeneratedDatabase {
  /// Compares and validates the schema of the current database with what the
  /// generated code expects.
  ///
  /// When changing tables or other elements of your database schema, you need
  /// to increate your [GeneratedDatabase.schemaVersion] and write a migration
  /// to transform your existing tables to the new structure.
  ///
  /// For queries, drift always assumes that your database schema matches the
  /// structure of your defined tables. This isn't the case when you forget to
  /// write a schema migration, which can cause all kinds of problems later.
  ///
  /// For this reason, the [validateDatabaseSchema] method can be used in your
  /// database, (perhaps in a [MigrationStrategy.beforeOpen] callback) to verify
  /// that your database schema is what drift expects.
  ///
  /// The [common.ValidationOptions] can be used to make the schema validation
  /// more strict (e.g. by enabling [common.ValidationOptions.validateDropped]
  /// to ensure that no old tables continue to exist if they're not referenced
  /// in the new schema) or more lenient (e.g. by disabling
  /// [common.ValidationOptions.validateColumnConstraints]).
  ///
  /// This variant of [validateDatabaseSchema] is only supported on native
  /// platforms (Android, iOS, macOS, Linux and Windows).
  Future<void> validateDatabaseSchema({
    common.ValidationOptions options = const common.ValidationOptions(),
    @Deprecated('Use field in ValidationOptions instead') bool? validateDropped,
  }) async {
    await verifyDatabase(
      this,
      options.applyDeprecatedValidateDroppedParam(validateDropped),
      NativeDatabase.memory,
    );
  }
}

/// Contains an initialized schema with all tables, views, triggers and indices.
///
/// You can use the [common.InitializedSchema.newConnection] for your database
/// class and the [common.InitializedSchema.rawDatabase] to insert data before
/// the migration.
typedef InitializedSchema = common.InitializedSchema<Database>;
