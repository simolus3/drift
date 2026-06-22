/// Port of [`validateDatabaseSchema`](https://drift.simonbinder.eu/migrations/tests/#verifying-a-database-schema-at-runtime)
/// to a preview of drift version 3.
library;

import 'package:drift3/drift.dart';

import 'package:drift_dev/api/migrations_common.dart' as common;
import 'package:drift_dev/src/services/schema/find_differences.dart';
import 'package:drift_dev/src/services/schema/verifier_common.dart';

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
  /// The [common.ValidationOptions] can be used to make the schema validation
  /// more strict (e.g. by enabling [common.ValidationOptions.validateDropped]
  /// to ensure that no old tables continue to exist if they're not referenced
  /// in the new schema) or more lenient (e.g. by disabling
  /// [common.ValidationOptions.validateColumnConstraints]).
  ///
  /// This variant of [validateDatabaseSchema] is only supported on native
  /// platforms (Android, iOS, macOS, Linux and Windows).
  Future<void> validateDatabaseSchema({
    required DriftConnection connection,
    common.ValidationOptions options = const common.ValidationOptions(),
  }) async {
    await _verifyDrift3Database(this, options, connection);
  }
}

Future<void> _verifyDrift3Database(
  GeneratedDatabase db,
  common.ValidationOptions options,
  DriftConnection connection,
) async {
  final virtualTables = db.schema
      .whereType<VirtualTableInfo>()
      .map((e) => e.entityName)
      .toList();

  final schemaOfThisDatabase = await db.collectSchemaInput(virtualTables);

  // The expectedSchema expando will store the expected schema for this
  // database when it's opened in a migration test. This allows this method
  // to be used in migration tests -- otherwise, this would always compare the
  // runtime schema to the latest schema from generated code.
  var referenceSchema = expectedSchema[db];

  if (referenceSchema == null) {
    // Collect the schema how it would be if we just called `createAll` on a
    // clean database.
    final referenceDb = _GenerateFromScratchDrift3(db, connection);
    referenceSchema =
        expectedSchema[db] ??
        await referenceDb.collectSchemaInput(virtualTables);
    await referenceDb.close();
  }

  verify(referenceSchema, schemaOfThisDatabase, options);
}

final class _GenerateFromScratchDrift3 extends GeneratedDatabase {
  final GeneratedDatabase reference;

  _GenerateFromScratchDrift3(this.reference, super.implementation);

  @override
  DatabaseSchema get schema => reference.schema;

  @override
  int get schemaVersion => reference.schemaVersion;
}

extension CollectSchemaDbDrift3 on DatabaseConnectionUser {
  Future<List<Input>> collectSchemaInput(List<String> virtualTables) async {
    final result = await customSelect(
      'SELECT name, sql FROM sqlite_master WHERE sql IS NOT NULL;',
    ).get();
    final inputs = <Input>[];

    for (final row in result) {
      final [name, sql] = row.row.cast<String>();
      // ignore: invalid_use_of_internal_member
      final input = parseInputFromSchemaRow(name, sql, virtualTables);
      if (input != null) {
        inputs.add(input);
      }
    }

    return inputs;
  }
}
