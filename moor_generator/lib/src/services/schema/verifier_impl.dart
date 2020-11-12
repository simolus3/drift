import 'dart:math';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:moor_generator/api/migrations.dart';
import 'package:sqlite3/sqlite3.dart';

import 'find_differences.dart';

class VerifierImplementation implements SchemaVerifier {
  final SchemaInstantiationHelper helper;
  final Random _random = Random();

  VerifierImplementation(this.helper);

  @override
  Future<void> migrateAndValidate(GeneratedDatabase db, int expectedVersion,
      {bool validateDropped = false}) async {
    // Open the database to collect its schema. Put a delegate in between
    // claiming that the actual version is what we expect.
    await db.executor.ensureOpen(_DelegatingUser(expectedVersion, db));
    final actualSchema = await db.executor.collectSchemaInput();

    // Open another connection to instantiate and extract the reference schema.
    final otherConnection = await startAt(expectedVersion);
    await otherConnection.executor.ensureOpen(_DelegatingUser(expectedVersion));
    final referenceSchema = await otherConnection.executor.collectSchemaInput();
    await otherConnection.executor.close();

    final result =
        FindSchemaDifferences(referenceSchema, actualSchema, validateDropped)
            .compare();

    if (!result.noChanges) {
      throw SchemaMismatch(result.describe());
    }
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
  Future<DatabaseConnection> startAt(int version) async {
    // Use distinct executors for setup and use, allowing us to close the helper
    // db here and avoid creating it twice.
    // https://www.sqlite.org/inmemorydb.html#sharedmemdb
    final uri = 'file:mem${_randomString()}?mode=memory&cache=shared';
    final dbForSetup = sqlite3.open(uri, uri: true);
    final dbForUse = sqlite3.open(uri, uri: true);

    final executor = VmDatabase.opened(dbForSetup);
    final db = helper.databaseForVersion(executor, version);

    // Opening the helper database will instantiate the schema for us
    await executor.ensureOpen(db);
    await executor.runCustom('PRAGMA schema_version = $version;');
    await db.close();

    return DatabaseConnection.fromExecutor(VmDatabase.opened(dbForUse));
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

class _DelegatingUser extends QueryExecutorUser {
  @override
  final int schemaVersion;
  final QueryExecutorUser inner;

  _DelegatingUser(this.schemaVersion, [this.inner]);

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return inner?.beforeOpen(executor, details) ?? Future.value();
  }
}
