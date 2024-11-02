import 'package:drift/drift.dart';
import 'package:drift/internal/migrations.dart';
import 'package:drift/wasm.dart';
import 'package:drift_dev/src/services/schema/verifier_web.dart' as impl;
import 'package:drift_dev/src/services/schema/verifier_common.dart';
import 'package:sqlite3/wasm.dart';

import 'migrations_common.dart' as common;

export 'migrations_common.dart'
    show SchemaMismatch, SchemaInstantiationHelper, MissingSchemaException;

abstract class WebSchemaVerifier
    implements common.SchemaVerifier<CommonDatabase> {
  /// Creates a schema verifier for the drift-generated [helper].
  ///
  /// See [tests] for more information.
  /// The optional [setup] parameter is used internally by the verifier for
  /// every database connection it opens. This can be used to, for instance,
  /// register custom functions expected by your database.
  ///
  /// [tests]: https://drift.simonbinder.eu/docs/migrations/tests/
  factory WebSchemaVerifier(
    CommonSqlite3 sqlite3,
    SchemaInstantiationHelper helper, {
    void Function(CommonDatabase raw)? setup,
  }) = impl.WebSchemaVerifier;
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
  /// When [validateDropped] is enabled (it is by default), this method also
  /// verifies that all schema elements that you've deleted at some point are no
  /// longer present in your runtime schema.
  ///
  /// This variant of [validateDatabaseSchema] is only supported on native
  /// platforms (Android, iOS, macOS, Linux and Windows).
  Future<void> validateDatabaseSchema({
    required CommonSqlite3 sqlite3,
    bool validateDropped = true,
  }) async {
    await verifyDatabase(
        this, validateDropped, () => WasmDatabase.inMemory(sqlite3));
  }
}
