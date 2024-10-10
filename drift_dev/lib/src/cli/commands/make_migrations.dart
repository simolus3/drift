import 'dart:convert';
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/cli/cli.dart';
import 'package:drift_dev/src/cli/commands/schema.dart';
import 'package:drift_dev/src/cli/commands/schema/generate_utils.dart';
import 'package:drift_dev/src/cli/commands/schema/steps.dart';
import 'package:collection/collection.dart';

import 'package:drift_dev/src/services/schema/schema_files.dart';
import 'package:io/ansi.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

class MakeMigrationCommand extends DriftCommand {
  MakeMigrationCommand(super.cli);

  @override
  String get description => """
Generates migrations utilities for drift databases

${styleBold.wrap("Usage")}:

After defining your database for the first time, run this command to save the schema.
When you are ready to make changes to the database, alter the schema in the database file, bump the schema version and run this command again.
This will generate the following:

1. A steps file which contains a helper function to write a migration from one version to another.

  Example:
  ${blue.wrap("class")} ${green.wrap("Database")} ${blue.wrap("extends")} ${green.wrap("_\$Database")} ${yellow.wrap("{")}

    ...

    ${lightCyan.wrap("@override")}
    ${green.wrap("MigrationStrategy")} ${blue.wrap("get")} ${lightCyan.wrap("migration")} ${magenta.wrap("{")}
      ${magenta.wrap("return")} ${green.wrap("MigrationStrategy")}${blue.wrap("(")}
        ${lightCyan.wrap("onUpgrade")}: ${yellow.wrap("stepByStep(")}
          ${lightCyan.wrap("from1To2")}: ${magenta.wrap("(")}${lightCyan.wrap("m")}, ${lightCyan.wrap("schema")}${magenta.wrap(")")} ${magenta.wrap("async {")}
            ${magenta.wrap("await")} ${lightCyan.wrap("m")}.${yellow.wrap("stepByStep")}${blue.wrap("(")}${lightCyan.wrap("schema.todoEntries")}, ${lightCyan.wrap("schema.todoEntries.dueDate")}${blue.wrap(")")};
          ${magenta.wrap("}")}${yellow.wrap(")")},
      ${blue.wrap(")")};
    ${yellow.wrap("}")}

2. A test file which contains tests to validate that the migrations are correct. This will allow you to try out your migrations easily.

3. (Optional) The generated test can also be used to validate the data integrity of the migrations. 
  Fill the generated validation models with data that should be present in the database before and after the migration.
  These lists will be imported in the test file to validate the data integrity of the migrations

  Example:
  // Validate that the data in the database is still correct after removing a the isAdmin column
  ${blue.wrap("final")} ${lightCyan.wrap("usersV1")} = ${yellow.wrap("[")}
    v1.${green.wrap("User")}${magenta.wrap("(")}${lightCyan.wrap("id")}: ${green.wrap("Value")}${blue.wrap("(")}1${blue.wrap(")")}, ${lightCyan.wrap("name")}: ${green.wrap("Value")}${blue.wrap("(")}${lightRed.wrap("'Simon'")}${blue.wrap(")")}, ${lightCyan.wrap("isAdmin")}: ${green.wrap("Value")}${blue.wrap("(")}${blue.wrap("true")}${blue.wrap(")")}${magenta.wrap(")")},
    v1.${green.wrap("User")}${magenta.wrap("(")}${lightCyan.wrap("id")}: ${green.wrap("Value")}${blue.wrap("(")}2${blue.wrap(")")}, ${lightCyan.wrap("name")}: ${green.wrap("Value")}${blue.wrap("(")}${lightRed.wrap("'John'")}${blue.wrap(")")}, ${lightCyan.wrap("isAdmin")}: ${green.wrap("Value")}${blue.wrap("(")}${blue.wrap("false")}${blue.wrap(")")}${magenta.wrap(")")},
  ${yellow.wrap("]")};

  ${blue.wrap("final")} ${lightCyan.wrap("usersV2")} = ${yellow.wrap("[")}
    v2.${green.wrap("User")}${magenta.wrap("(")}${lightCyan.wrap("id")}: ${green.wrap("Value")}${blue.wrap("(")}1${blue.wrap(")")}, ${lightCyan.wrap("name")}: ${green.wrap("Value")}${blue.wrap("(")}${lightRed.wrap("'Simon'")}${blue.wrap(")")}${magenta.wrap(")")},
    v2.${green.wrap("User")}${magenta.wrap("(")}${lightCyan.wrap("id")}: ${green.wrap("Value")}${blue.wrap("(")}2${blue.wrap(")")}, ${lightCyan.wrap("name")}: ${green.wrap("Value")}${blue.wrap("(")}${lightRed.wrap("'John'")}${blue.wrap(")")}${magenta.wrap(")")},
  ${yellow.wrap("]")};

${styleBold.wrap("Configuration")}:

This tool requires the database be defined in the build.yaml file.
Example:

${blue.wrap("""
targets:
  \$default:
    builders:
      drift_dev:
        options:""")}
          ${green.wrap("# Required: The name of the database and the path to the database file")}
          ${blue.wrap("databases")}:
            ${blue.wrap("my_database")}: ${lightRed.wrap("lib/database.dart")}

            ${green.wrap("# Optional: Add more databases")}
            ${blue.wrap("another_db")}: ${lightRed.wrap("lib/database2.dart")}


          ${green.wrap("# Optional: The directory where the test files are stored")}: 
          ${blue.wrap("test_dir")}: ${lightRed.wrap("test/drift/")} ${green.wrap("# (default)")}

          ${green.wrap("# Optional: The directory where the schema files are stored")}:
          ${blue.wrap("schema_dir")}: ${lightRed.wrap("drift_schemas/")}  ${green.wrap("# (default)")}

""";

  @override
  String get name => "make-migrations";

  @override
  Future<void> run() async {
    if (p.isAbsolute(cli.project.options.schemaDir)) {
      cli.exit(
          '`schema_dir` must be a relative path. Remove the leading slash');
    }
    if (p.isAbsolute(cli.project.options.testDir)) {
      cli.exit('`test_dir` must be a relative path. Remove the leading slash');
    }

    /// The root directory where test files for all databases are stored
    /// e.g /test/drift/
    final rootSchemaDir = Directory(
        p.join(cli.project.directory.path, cli.project.options.schemaDir))
      ..createSync(recursive: true);

    /// The root directory where schema files for all databases are stored
    /// e.g /drift_schemas/
    final rootTestDir = Directory(
        p.join(cli.project.directory.path, cli.project.options.testDir))
      ..createSync(recursive: true);

    if (cli.project.options.databases.isEmpty) {
      cli.exit(
          'No databases found in the build.yaml file. Run `drift_dev make-migrations --help` or check the documentation for more information: https://drift.simonbinder.eu/Migrations/');
    }

    final databaseMigrationsWriters =
        await Future.wait(cli.project.options.databases.entries.map(
      (entry) async {
        final writer = await _MigrationTestEmitter.create(
            cli: cli,
            rootSchemaDir: rootSchemaDir,
            rootTestDir: rootTestDir,
            dbName: entry.key,
            relativeDbClassPath: entry.value);
        return writer;
      },
    ));

    for (var writer in databaseMigrationsWriters) {
      // Dump the schema files for all databases
      await writer.writeSchemaFile();
      if (writer.schemas.length == 1) {
        continue;
      }
      // Write the step by step migration files for all databases
      // This is done after all the schema files have been written to the disk
      // to ensure that the schema files are up to date
      await writer.writeStepsFile();
      // Write the generated test databases
      await writer.writeTestDatabases();
      // Write the generated test
      await writer.writeTest();
      writer.flush();
    }
  }
}

class _MigrationTestEmitter {
  final DriftDevCli cli;
  final Directory rootSchemaDir;
  final Directory rootTestDir;
  final String dbName;
  late final File dbClassFile;

  /// The directory where the schema files for this database are stored
  /// e.g /drift_schemas/my_database/
  final Directory schemaDir;

  /// The directory where the tests for this database are stored
  /// e.g /test/drift/my_database/
  final Directory testDir;

  /// The directory where the generated test utils are stored
  /// e.g /test/drift/my_database/generated/
  final Directory testDatabasesDir;

  /// Current schema version of the database
  final int schemaVersion;

  /// The name of the database class
  final String dbClassName;

  /// The parsed database class
  final DriftDatabase db;

  /// The parsed drift elements
  final List<DriftElement> driftElements;

  /// Stores the tempoarary files to be written to the disk
  /// Only is written to the disk once the entire generation process completes without errors
  final writeTasks = <File, String>{};

  /// Write all the files to the disk
  void flush() {
    for (var MapEntry(key: file, value: content) in writeTasks.entries) {
      if (file.path.endsWith('.dart')) {
        content = DartFormatter().format(content);
      }
      file.writeAsStringSync(content);
    }
    writeTasks.clear();
  }

  /// All the schema files for this database
  Map<int, ExportedSchema> schemas;

  /// Migration writer for each migration
  List<_MigrationWriter> get migrations => _MigrationWriter.fromSchema(schemas);

  _MigrationTestEmitter({
    required this.cli,
    required this.rootSchemaDir,
    required this.rootTestDir,
    required this.dbName,
    required this.dbClassFile,
    required this.schemaDir,
    required this.testDir,
    required this.testDatabasesDir,
    required this.schemaVersion,
    required this.dbClassName,
    required this.db,
    required this.driftElements,
    required this.schemas,
  });

  static Future<_MigrationTestEmitter> create(
      {required DriftDevCli cli,
      required Directory rootSchemaDir,
      required Directory rootTestDir,
      required String dbName,
      required String relativeDbClassPath}) async {
    if (p.isAbsolute(relativeDbClassPath)) {
      cli.exit(
          'The path for the "$dbName" database must be a relative path. Remove the leading slash');
    }
    if (!relativeDbClassPath.endsWith(".dart")) {
      if (dbName == "schema_dir" || dbName == "test_dir") {
        cli.exit(
            "The path for the $dbName must be a dart file. It seems you have $dbName under the `options` section in the build.yaml file instead of under the `databases` section");
      } else {
        cli.exit('The path for the "$dbName" database must be a dart file');
      }
    }

    final dbClassFile =
        File(p.join(cli.project.directory.path, relativeDbClassPath));
    final schemaDir = Directory(p.join(rootSchemaDir.path, dbName))
      ..createSync(recursive: true);
    final testDir = Directory(p.join(rootTestDir.path, dbName))
      ..createSync(recursive: true);
    final testDatabasesDir = Directory(p.join(testDir.path, 'generated'))
      ..createSync(recursive: true);
    final (:db, :elements, :schemaVersion) =
        await cli.readElementsFromSource(dbClassFile.absolute);
    if (schemaVersion == null) {
      cli.exit('Could not read schema version from the "$dbName" database.');
    }
    if (db == null) {
      cli.exit('Could not read database class from the "$dbName" database.');
    }
    final schemas = await parseSchema(schemaDir);
    return _MigrationTestEmitter(
        cli: cli,
        rootSchemaDir: rootSchemaDir,
        rootTestDir: rootTestDir,
        dbName: dbName,
        dbClassFile: dbClassFile,
        schemaDir: schemaDir,
        testDir: testDir,
        db: db,
        schemas: schemas,
        driftElements: elements,
        dbClassName: db.definingDartClass.toString(),
        testDatabasesDir: testDatabasesDir,
        schemaVersion: schemaVersion);
  }

  /// Create a .json dump of the current schema
  /// This file is written instantly to the disk
  Future<void> writeSchemaFile() async {
    // If the latest schema file version is larger than the current schema version
    // then something is wrong
    if (schemas.keys.any((v) => v > schemaVersion)) {
      cli.exit(
          'The version of your $dbName database ($schemaVersion) is lower than the latest schema version. '
          'The schema version in the database should never be decreased. ');
    }

    final writer = SchemaWriter(driftElements, options: cli.project.options);
    final schemaFile = driftSchemaFile(schemaVersion);
    final content = json.encode(writer.createSchemaJson());
    if (!schemaFile.existsSync()) {
      cli.logger
          .info('$dbName: Creating schema file for version $schemaVersion');
      schemaFile.writeAsStringSync(content);
      // Re-parse the schema to include the newly created schema file
      schemas = await parseSchema(schemaDir);
    } else if (schemaFile.readAsStringSync() != content) {
      cli.exit(
          "A schema for version $schemaVersion of the $dbName database already exists and differs from the current schema."
          " Either delete the existing schema file or update the schema version in the database file.");
    }
  }

  /// Create a step by step migration file
  Future<void> writeStepsFile() async {
    if (!stepsFile.existsSync()) {
      cli.logger.info(
          """$dbName: Generated step by step migration helper in ${blue.wrap(p.relative(stepsFile.path))}
Use this generated `${yellow.wrap("stepByStep")}` to write your migrations.
Example:

${blue.wrap("class")} ${green.wrap(dbClassName)} ${blue.wrap("extends")} ${green.wrap("_\$$dbClassName")} ${yellow.wrap("{")}

  ...

  ${lightCyan.wrap("@override")}
  ${green.wrap("MigrationStrategy")} ${blue.wrap("get")} ${lightCyan.wrap("migration")} ${magenta.wrap("{")}
    ${magenta.wrap("return")} ${green.wrap("MigrationStrategy")}${blue.wrap("(")}
      ${lightCyan.wrap("onUpgrade")}: ${yellow.wrap("stepByStep(")}
        ${lightCyan.wrap("from1To2")}: ${magenta.wrap("(")}${lightCyan.wrap("m")}, ${lightCyan.wrap("schema")}${magenta.wrap(")")} ${magenta.wrap("async {")}
          ${backgroundGreen.wrap("// Write your migrations here")}
        ${magenta.wrap("}")}${yellow.wrap(")")},
    ${blue.wrap(")")};
  ${yellow.wrap("}")}
""");
    } else {
      cli.logger.fine(
          "$dbName: Updating step by step migration helper in ${blue.wrap(p.relative(stepsFile.path))}");
    }
    writeTasks[stepsFile] =
        StepsGenerationUtil.generateStepByStepMigration(schemas);
  }

  /// Generate a built database for each schema version
  /// This will be used to test the migrations
  Future<void> writeTestDatabases() async {
    for (final versionAndEntities in schemas.entries) {
      final version = versionAndEntities.key;
      final entities = versionAndEntities.value;
      writeTasks[testUtilityFile(version)] =
          GenerateUtils.generateSchemaCode(cli, version, entities, true, true);
    }
    writeTasks[File(p.join(testDatabasesDir.path, 'schema.dart'))] =
        GenerateUtils.generateLibraryCode(schemas.keys);
  }

  Future<void> writeTest() async {
    final testFile = File(p.join(testDir.path, 'migration_test.dart'));
    if (testFile.existsSync()) {
      return;
    }
    if (migrations.isEmpty) {
      return;
    }

    final firstMigration =
        migrations.sorted((a, b) => a.from.compareTo(b.from)).first;

    final packageName = cli.project.buildConfig.packageName;
    final relativeDbPath = p.relative(dbClassFile.path,
        from: p.join(cli.project.directory.path, 'lib'));

    final code = """
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:$packageName/$relativeDbPath';
import 'package:test/test.dart';
import 'generated/schema.dart';

${firstMigration.schemaImports().join('\n')}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('$dbName database', () {
  //////////////////////////////////////////////////////////////////////////////
  ////////////////////// GENERATED TESTS - DO NOT MODIFY ///////////////////////
  //////////////////////////////////////////////////////////////////////////////
    if (GeneratedHelper.versions.length < 2) return;
    for (var i
        in List.generate(GeneratedHelper.versions.length - 1, (i) => i)) {
      final oldVersion = GeneratedHelper.versions.elementAt(i);
      final newVersion = GeneratedHelper.versions.elementAt(i + 1);
      test("migrate from v\$oldVersion to v\$newVersion", () async {
        final schema = await verifier.schemaAt(oldVersion);
        final db = $dbClassName(schema.newConnection());
        await verifier.migrateAndValidate(db, newVersion);
        await db.close();
      });
  }
  //////////////////////////////////////////////////////////////////////////////
  /////////////////////// END OF GENERATED TESTS ///////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  ${firstMigration.testStepByStepMigrationCode(dbName, dbClassName)}
  });
  
}
""";

    cli.logger.info(
        '$dbName: Generated test in ${blue.wrap(p.relative(testFile.path))}.\n'
        'Run this test to validate that your migrations are written correctly. ${yellow.wrap("dart test ${blue.wrap(p.relative(testFile.path))}")}');
    writeTasks[testFile] = code;
  }

  /// The json file where the schema for the current version of the database is stored
  File driftSchemaFile(int version) {
    return File(p.join(schemaDir.path, 'drift_schema_v$version.json'));
  }

  File testUtilityFile(int version) {
    return File(p.join(testDatabasesDir.path, 'schema_v$version.dart'));
  }

  /// Generated file where the step by step migration code is stored
  File get stepsFile {
    return File(dbClassFile.absolute.path
        .replaceFirst(RegExp(r'\.dart$'), '.steps.dart'));
  }
}

/// A writer that generates the code for a migration from one schema version to another
class _MigrationWriter {
  final List<DriftTable> tables;
  final int from;
  final int to;

  _MigrationWriter(this.tables, {required this.from, required this.to});

  /// Create  list of migration writers from a map of schema versions
  /// A migration writer is created for each pair of schema versions
  /// e.g (1,2), (2,3), (3,4) etc
  static List<_MigrationWriter> fromSchema(Map<int, ExportedSchema> schemas) {
    final result = <_MigrationWriter>[];
    if (schemas.length < 2) {
      return result;
    }
    final versions = schemas.keys.toList()..sort();
    for (var i = 0; i < versions.length - 1; i++) {
      final (from, fromSchema) = (versions[i], schemas[versions[i]]!);
      final (to, toSchema) = (versions[i + 1], schemas[versions[i + 1]]!);
      final fromTables = fromSchema.schema.whereType<DriftTable>();
      final toTables = toSchema.schema.whereType<DriftTable>();
      final commonTables = fromTables.where(
          (table) => toTables.any((t) => t.schemaName == table.schemaName));
      result.add(_MigrationWriter(commonTables.toList(), from: from, to: to));
    }
    return result;
  }

  List<String> schemaImports() {
    return [
      "import 'generated/schema_v$from.dart' as v$from;",
      "import 'generated/schema_v$to.dart' as v$to;"
    ];
  }

  /// Generate a step by step migration test
  /// This test will test the migration from version [from] to version [to]
  /// It will also import the validation models to test data integrity
  String testStepByStepMigrationCode(String dbName, String dbClassName) {
    return """
//////////////////////////////////////////////////////////////////////////////
    ///////////////////// CUSTOM TESTS - MODIFY AS NEEDED ////////////////////////
    //////////////////////////////////////////////////////////////////////////////
test("migration from v$from to v$to does not corrupt data",
      () async {
    // TODO: Consider writing these kinds of tests when altering tables in a way that might affect existing rows.
    // The automatically generated migration tests run with an empty schema, so it's a recommended practice to also test with
    // data for relevant migrations.
    ${tables.map((table) {
      return """
final old${table.dbGetterName.pascalCase}Data = <v$from.${table.nameOfRowClass}>[]; // TODO: Add expected data at version $from using v$from.${table.nameOfRowClass}
final expectedNew${table.dbGetterName.pascalCase}Data = <v$to.${table.nameOfRowClass}>[]; // TODO: Add expected data at version $to using v$to.${table.nameOfRowClass}
""";
    }).join('\n')}

    await verifier.testWithDataIntegrity(
      oldVersion: $from,
      newVersion: $to,
      verifier: verifier,
      createOld: (e) => v1.DatabaseAtV$from(e),
      createNew: (e) => v2.DatabaseAtV$to(e),
      openTestedDatabase: (e) => $dbClassName(e),
      createItems: (batch, oldDb) {
        ${tables.map(
      (table) {
        return "batch.insertAll(oldDb.${table.dbGetterName}, old${table.dbGetterName.pascalCase}Data);";
      },
    ).join('\n')}
      },
      validateItems: (newDb) async {
        ${tables.map(
      (table) {
        return "expect(expectedNew${table.dbGetterName.pascalCase}Data, await newDb.select(newDb.${table.dbGetterName}).get());";
      },
    ).join('\n')}
      },
    );
  });
  ///////////////////////////////////////////////////////////////////////////////
  /////////////////////// END OF CUSTOM TESTS ///////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
""";
  }
}
