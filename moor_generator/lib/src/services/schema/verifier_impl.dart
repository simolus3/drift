import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:moor_generator/api/migrations.dart';

import 'find_differences.dart';

class VerifierImplementation implements SchemaVerifier {
  final SchemaInstantiationHelper helper;

  VerifierImplementation(this.helper);

  @override
  Future<void> migrateAndValidate(GeneratedDatabase db, int expectedVersion,
      {bool validateDropped = false}) async {
    final versionBefore = await db.runtimeSchemaVersion;
    // The database most likely uses a connection obtained through startAt,
    // which has already been opened. So, instead of calling ensureOpen we
    // emulate a migration run by calling beforeOpen manually.
    await db.beforeOpen(
        db.executor, OpeningDetails(versionBefore, expectedVersion));
    await db.customStatement('PRAGMA schema_version = $expectedVersion');

    final otherConnection = await startAt(expectedVersion);
    final referenceSchema = await otherConnection.executor.collectSchemaInput();
    final actualSchema = await db.executor.collectSchemaInput();

    final result =
        FindSchemaDifferences(referenceSchema, actualSchema, validateDropped)
            .compare();

    if (!result.noChanges) {
      throw SchemaMismatch(result.describe());
    }
  }

  @override
  Future<DatabaseConnection> startAt(int version) async {
    final executor = VmDatabase.memory();
    final db = helper.databaseForVersion(executor, version);

    // Opening the helper database will instantiate the schema for us
    await executor.ensureOpen(db);

    return DatabaseConnection.fromExecutor(executor);
  }
}

extension on QueryEngine {
  Future<int> get runtimeSchemaVersion async {
    final row = await customSelect('PRAGMA schema_version;').getSingle();
    return row.readInt('schema_version');
  }
}

extension on QueryExecutor {
  Future<List<Input>> collectSchemaInput() async {
    final result = await runSelect('SELECT * FROM sqlite_master;', const []);

    final inputs = <Input>[];
    for (final row in result) {
      final name = row['name'] as String;
      if (name.startsWith('sqlite_autoindex')) continue;

      inputs.add(Input(name, row['sql'] as String));
    }

    return inputs;
  }
}
