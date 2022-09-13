import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:sqlite3/sqlite3.dart';

import 'find_differences.dart';

class VerifierImplementation implements SchemaVerifier {
  final SchemaInstantiationHelper helper;
  final Random _random = Random();

  VerifierImplementation(this.helper);

  @override
  Future<void> migrateAndValidate(GeneratedDatabase db, int expectedVersion,
      {bool validateDropped = false}) async {
    final virtualTables = <String>[
      for (final table in db.allTables)
        if (table is VirtualTableInfo) table.entityName,
    ];

    // Open the database to collect its schema. Put a delegate in between
    // claiming that the actual version is what we expect.
    await db.executor.ensureOpen(_DelegatingUser(expectedVersion, db));
    final actualSchema = await db.executor.collectSchemaInput(virtualTables);

    // Open another connection to instantiate and extract the reference schema.
    final otherConnection = await startAt(expectedVersion);
    await otherConnection.executor.ensureOpen(_DelegatingUser(expectedVersion));
    final referenceSchema =
        await otherConnection.executor.collectSchemaInput(virtualTables);
    await otherConnection.executor.close();

    verify(referenceSchema, actualSchema, validateDropped);
  }

  String _randomString() {
    const charCodeLowerA = 97;
    const charCodeLowerZ = 122;
    const length = 16;

    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.writeCharCode(
          _random.nextInt(charCodeLowerZ - charCodeLowerA) + charCodeLowerA);
    }

    return buffer.toString();
  }

  @override
  Future<InitializedSchema> schemaAt(int version) async {
    // Use distinct executors for setup and use, allowing us to close the helper
    // db here and avoid creating it twice.
    // https://www.sqlite.org/inmemorydb.html#sharedmemdb
    final uri = 'file:mem${_randomString()}?mode=memory&cache=shared';
    final dbForSetup = sqlite3.open(uri, uri: true);
    final dbForUse = sqlite3.open(uri, uri: true);

    final executor = NativeDatabase.opened(dbForSetup);
    final db = helper.databaseForVersion(executor, version);

    // Opening the helper database will instantiate the schema for us
    await executor.ensureOpen(db);
    await executor.runCustom('PRAGMA schema_version = $version;');
    await db.close();

    return InitializedSchema(dbForUse, () {
      final db = sqlite3.open(uri, uri: true);
      return DatabaseConnection(NativeDatabase.opened(db));
    });
  }

  @override
  Future<DatabaseConnection> startAt(int version) {
    return schemaAt(version).then((schema) => schema.newConnection());
  }
}

Input? _parseInputFromSchemaRow(
    Map<String, Object?> row, List<String> virtualTables) {
  final name = row['name'] as String;

  // Skip sqlite-internal tables, https://www.sqlite.org/fileformat2.html#intschema
  if (name.startsWith('sqlite_')) return null;
  if (virtualTables.any((v) => name.startsWith('${v}_'))) return null;

  // This file is added on some Android versions when using the native Android
  // database APIs, https://github.com/simolus3/drift/discussions/2042
  if (name == 'android_metadata') return null;

  return Input(name, row['sql'] as String);
}

extension CollectSchemaDb on DatabaseConnectionUser {
  Future<List<Input>> collectSchemaInput(List<String> virtualTables) async {
    final result = await customSelect('SELECT * FROM sqlite_master;').get();
    final inputs = <Input>[];

    for (final row in result) {
      final input = _parseInputFromSchemaRow(row.data, virtualTables);
      if (input != null) {
        inputs.add(input);
      }
    }

    return inputs;
  }
}

extension CollectSchema on QueryExecutor {
  Future<List<Input>> collectSchemaInput(List<String> virtualTables) async {
    final result = await runSelect('SELECT * FROM sqlite_master;', const []);

    final inputs = <Input>[];
    for (final row in result) {
      final input = _parseInputFromSchemaRow(row, virtualTables);
      if (input != null) {
        inputs.add(input);
      }
    }

    return inputs;
  }
}

void verify(List<Input> referenceSchema, List<Input> actualSchema,
    bool validateDropped) {
  final result =
      FindSchemaDifferences(referenceSchema, actualSchema, validateDropped)
          .compare();

  if (!result.noChanges) {
    throw SchemaMismatch(result.describe());
  }
}

class _DelegatingUser extends QueryExecutorUser {
  @override
  final int schemaVersion;
  final QueryExecutorUser? inner;

  _DelegatingUser(this.schemaVersion, [this.inner]);

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return inner?.beforeOpen(executor, details) ?? Future.value();
  }
}
