import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:sqlite3/sqlite3.dart';

import 'find_differences.dart';
import 'verifier_common.dart';

Expando<List<Input>> expectedSchema = Expando();

class VerifierImplementation implements SchemaVerifier {
  final SchemaInstantiationHelper helper;
  final Random _random = Random();
  final void Function(Database)? setup;

  VerifierImplementation(this.helper, {this.setup});

  @override
  Future<void> migrateAndValidate(GeneratedDatabase db, int expectedVersion,
      {bool validateDropped = false}) async {
    final virtualTables = <String>[
      for (final table in db.allTables)
        if (table is VirtualTableInfo) table.entityName,
    ];

    // Open a connection to instantiate and extract the reference schema.
    final otherConnection = await startAt(expectedVersion);
    await otherConnection.executor.ensureOpen(_DelegatingUser(expectedVersion));
    final referenceSchema =
        await otherConnection.executor.collectSchemaInput(virtualTables);
    await otherConnection.executor.close();

    // Attach the reference schema to the database so that VerifySelf.validateDatabaseSchema
    // works
    expectedSchema[db] = referenceSchema;

    // Open the database to collect its schema. Put a delegate in between
    // claiming that the actual version is what we expect.
    await db.executor.ensureOpen(_DelegatingUser(expectedVersion, db));
    final actualSchema = await db.executor.collectSchemaInput(virtualTables);

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

  Database _setupDatabase(String uri) {
    final database = sqlite3.open(uri, uri: true);
    setup?.call(database);
    return database;
  }

  @override
  Future<InitializedSchema> schemaAt(int version) async {
    // Use distinct executors for setup and use, allowing us to close the helper
    // db here and avoid creating it twice.
    // https://www.sqlite.org/inmemorydb.html#sharedmemdb
    final uri = 'file:mem${_randomString()}?mode=memory&cache=shared';
    final dbForSetup = _setupDatabase(uri);
    final dbForUse = _setupDatabase(uri);

    final executor = NativeDatabase.opened(dbForSetup);
    final db = helper.databaseForVersion(executor, version);

    // Opening the helper database will instantiate the schema for us
    await executor.ensureOpen(db);
    await db.close();

    return InitializedSchema(dbForUse, () {
      final db = _setupDatabase(uri);
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
  if (isInternalElement(name, virtualTables)) {
    return null;
  }

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
