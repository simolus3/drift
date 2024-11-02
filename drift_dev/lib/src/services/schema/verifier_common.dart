import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_common.dart';
import 'package:sqlite3/common.dart';

import 'find_differences.dart';

/// Attempts to recognize whether [name] is likely the name of an internal
/// sqlite3 table (like `sqlite3_sequence`) that we should not consider when
/// comparing schemas.
bool isInternalElement(String name, List<String> virtualTables) {
  // Skip sqlite-internal tables, https://www.sqlite.org/fileformat2.html#intschema
  if (name.startsWith('sqlite_')) return true;
  if (virtualTables.any((v) => name.startsWith('${v}_'))) return true;

  // This file is added on some Android versions when using the native Android
  // database APIs, https://github.com/simolus3/drift/discussions/2042
  if (name == 'android_metadata') return true;

  return false;
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

Future<void> verifyDatabase(
  GeneratedDatabase db,
  bool validateDropped,
  QueryExecutor Function() open,
) async {
  final virtualTables = db.allTables
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
    final referenceDb = _GenerateFromScratch(db, open());
    referenceSchema = expectedSchema[db] ??
        await referenceDb.collectSchemaInput(virtualTables);
    await referenceDb.close();
  }

  verify(referenceSchema, schemaOfThisDatabase, validateDropped);
}

/// Thrown when the actual schema differs from the expected schema.
class SchemaMismatch implements Exception {
  final String explanation;

  SchemaMismatch(this.explanation);

  @override
  String toString() {
    return 'Schema does not match\n$explanation';
  }
}

Expando<List<Input>> expectedSchema = Expando();

abstract base class VerifierImplementation<DB extends CommonDatabase>
    implements SchemaVerifier<DB> {
  final SchemaInstantiationHelper helper;
  final Random _random = Random();

  final void Function(DB)? setup;

  VerifierImplementation(this.helper, {this.setup});

  DB newInMemoryDatabase(String uri);

  QueryExecutor wrapOpened(DB db);

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

  DB _setupDatabase(String uri) {
    final database = newInMemoryDatabase(uri);
    try {
      database.config.doubleQuotedStringLiterals = false;
    } on SqliteException {
      print(
        'Could not disable double-quoted string literals, migration tests '
        'may behave differently than sqlite3 in your app. Please consider '
        'updating sqlite3 on your system.',
      );
    }

    setup?.call(database);
    return database;
  }

  @override
  Future<InitializedSchema<DB>> schemaAt(int version) async {
    // Use distinct executors for setup and use, allowing us to close the helper
    // db here and avoid creating it twice.
    // https://www.sqlite.org/inmemorydb.html#sharedmemdb
    final uri = 'file:mem${_randomString()}?mode=memory&cache=shared';
    final dbForSetup = _setupDatabase(uri);
    final dbForUse = _setupDatabase(uri);

    final executor = wrapOpened(dbForSetup);
    final db = helper.databaseForVersion(executor, version);

    // Opening the helper database will instantiate the schema for us
    await executor.ensureOpen(db);
    await db.close();

    return InitializedSchema(dbForUse, () {
      final db = _setupDatabase(uri);
      return DatabaseConnection(wrapOpened(db));
    });
  }

  @override
  Future<DatabaseConnection> startAt(int version) {
    return schemaAt(version).then((schema) => schema.newConnection());
  }

  @override
  Future<void> testWithDataIntegrity<OldDatabase extends GeneratedDatabase,
          NewDatabase extends GeneratedDatabase>(
      {required OldDatabase Function(QueryExecutor p1) createOld,
      required NewDatabase Function(QueryExecutor p1) createNew,
      required GeneratedDatabase Function(QueryExecutor p1) openTestedDatabase,
      required void Function(Batch p1, OldDatabase p2) createItems,
      required Future Function(NewDatabase p1) validateItems,
      required int oldVersion,
      required int newVersion}) async {
    final schema = await schemaAt(oldVersion);

    final oldDb = createOld(schema.newConnection());
    await oldDb.batch((batch) => createItems(batch, oldDb));
    await oldDb.close();

    final db = openTestedDatabase(schema.newConnection());
    await migrateAndValidate(db, newVersion);
    await db.close();

    final newDb = createNew(schema.newConnection());
    await validateItems(newDb);
    await newDb.close();
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

class _GenerateFromScratch extends GeneratedDatabase {
  final GeneratedDatabase reference;

  _GenerateFromScratch(this.reference, QueryExecutor executor)
      : super(executor);

  @override
  DriftDatabaseOptions get options => reference.options;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => reference.allTables;

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities =>
      reference.allSchemaEntities;

  @override
  int get schemaVersion => 1;
}
