import 'package:drift3/drift.dart';

import 'common.dart';
import 'find_differences.dart';

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
  /// The [DriftConnection] is used to open a temporary SQLite database
  /// to create a reference schema. Typically, an in-memory SQLite connection is
  /// suitable for this purpose.
  ///
  /// The [ValidationOptions] can be used to make the schema validation
  /// more strict (e.g. by enabling [ValidationOptions.validateDropped]
  /// to ensure that no old tables continue to exist if they're not referenced
  /// in the new schema) or more lenient (e.g. by disabling
  /// [ValidationOptions.validateColumnConstraints]).
  ///
  /// This variant of [validateDatabaseSchema] is only supported on native
  /// platforms (Android, iOS, macOS, Linux and Windows).
  Future<void> validateDatabaseSchema({
    required DriftConnection connection,
    ValidationOptions options = const ValidationOptions(),
  }) async {
    final reference = SyntacticSchema.fromDeclaredDriftSchema(
      schema,
      dialect: dialect,
    );

    final actual = await SyntacticSchema.readFromDrift(await currentSession());
    verify(referenceSchema: reference, actualSchema: actual, options: options);
  }
}
