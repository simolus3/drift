//@dart=2.9
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:args/command_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/cli/cli.dart';
import 'package:drift_dev/src/services/schema/schema_files.dart';
import 'package:drift_dev/writer.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

class GenerateUtilsCommand extends Command {
  final MoorCli cli;

  GenerateUtilsCommand(this.cli) {
    argParser.addFlag(
      'null-safety',
      defaultsTo: null,
      help: 'Whether to generate null-safe test code.',
    );
    argParser.addFlag(
      'data-classes',
      defaultsTo: false,
      help: 'Whether to generate data classes for each schema version.',
    );
    argParser.addFlag(
      'companions',
      defaultsTo: false,
      help: 'Whether to generate companions for each schema version.',
    );
  }

  @override
  String get description {
    return 'Generate Dart code to help verify schema migrations.';
  }

  @override
  String get name => 'generate';

  @override
  String get invocation {
    return '${runner.executableName} schema generate <input> <output>';
  }

  @override
  Future<void> run() async {
    final isNnbd = (argResults['null-safety'] as bool) ??
        await _isCurrentPackageNullSafe();

    final isForMoor = argResults.arguments.contains('moor_generator');

    final rest = argResults.rest;
    if (rest.length != 2) {
      usageException('Expected input and output directories');
    }

    final inputDir = Directory(rest[0]);
    final outputDir = Directory(rest[1]);

    if (!await inputDir.exists()) {
      cli.exit('The provided input directory does not exist.');
    }

    if (!await outputDir.exists()) {
      await outputDir.create();
    }

    final schema = await _parseSchema(inputDir);
    for (final versionAndEntities in schema.entries) {
      final version = versionAndEntities.key;
      final entities = versionAndEntities.value;

      await _writeSchemaFile(
        outputDir,
        version,
        entities,
        isNnbd,
        argResults['data-classes'] as bool,
        argResults['companions'] as bool,
        isForMoor,
      );
    }

    await _writeLibraryFile(outputDir, schema.keys, isNnbd, isForMoor);
    print(
        'Wrote ${schema.length + 1} files into ${p.relative(outputDir.path)}');
  }

  Future<bool> _isCurrentPackageNullSafe() async {
    PackageConfig config;
    try {
      config = await findPackageConfig(Directory.current);
    } on Object {
      stderr.write('Could not determine whether to use null-safety. Please '
          'run this command in a Dart project, or try running `pub get` first');
      return false;
    }

    // Just use any file in the current package, the file doesn't have to exist.
    final ownPackage =
        config.packageOf(Uri.file(File('pubspec.yaml').absolute.path));
    if (ownPackage == null) return false;

    final version = ownPackage.languageVersion;
    final featureSet = FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: Version(version.major, version.minor, 0),
      flags: const [],
    );

    return featureSet.isEnabled(Feature.non_nullable);
  }

  Future<Map<int, List<MoorSchemaEntity>>> _parseSchema(
      Directory directory) async {
    final results = <int, List<MoorSchemaEntity>>{};

    await for (final entity in directory.list()) {
      final basename = p.basename(entity.path);
      final match = _filenames.firstMatch(basename);

      if (match == null || entity is! File) continue;

      final version = int.parse(match.group(1));
      final file = entity as File;
      final rawData = json.decode(await file.readAsString());

      final schema = SchemaReader.readJson(rawData as Map<String, dynamic>);
      results[version] = schema.entities.toList();
    }

    return results;
  }

  Future<void> _writeSchemaFile(
    Directory output,
    int version,
    List<MoorSchemaEntity> entities,
    bool nnbd,
    bool dataClasses,
    bool companions,
    bool isForMoor,
  ) {
    final writer = Writer(
      cli.project.moorOptions,
      generationOptions: GenerationOptions(
        forSchema: version,
        nnbd: nnbd,
        writeCompanions: companions,
        writeDataClasses: dataClasses,
        writeForMoorPackage: isForMoor,
      ),
    );
    final file = File(p.join(output.path, _filenameForVersion(version)));

    final leaf = writer.leaf()
      ..writeln(_prefix)
      ..writeDartVersion(nnbd);

    if (isForMoor) {
      leaf.writeln("import 'package:moor/moor.dart';");
    } else {
      leaf.writeln("import 'package:drift/drift.dart';");
    }

    final db = Database(
      declaredQueries: const [],
      declaredIncludes: const [],
      declaredTables: const [],
    )..entities = entities;
    DatabaseWriter(db, writer.child()).write();

    return file.writeAsString(_dartfmt.format(writer.writeGenerated()));
  }

  Future<void> _writeLibraryFile(Directory output, Iterable<int> versions,
      bool nnbd, bool useMoorImports) {
    final buffer = StringBuffer()
      ..writeln(_prefix)
      ..writeDartVersion(nnbd);

    if (useMoorImports) {
      buffer
        ..writeln("import 'package:moor/moor.dart';")
        ..writeln("import 'package:moor_generator/api/migrations.dart';");
    } else {
      buffer
        ..writeln("import 'package:drift/drift.dart';")
        ..writeln("import 'package:drift_dev/api/migrations.dart';");
    }

    for (final version in versions) {
      buffer.writeln("import '${_filenameForVersion(version)}' as v$version;");
    }

    buffer
      ..writeln('class GeneratedHelper implements SchemaInstantiationHelper {')
      ..writeln('@override')
      ..writeln('GeneratedDatabase databaseForVersion(QueryExecutor db, '
          'int version) {')
      ..writeln('switch (version) {');

    for (final version in versions) {
      buffer
        ..writeln('case $version:')
        ..writeln('return v$version.DatabaseAtV$version(db);');
    }

    final missingAsSet = '{${versions.join(', ')}}';
    buffer
      ..writeln('default:')
      ..writeln('throw MissingSchemaException(version, const $missingAsSet);')
      ..writeln('}}}');

    final file = File(p.join(output.path, 'schema.dart'));
    return file.writeAsString(_dartfmt.format(buffer.toString()));
  }

  String _filenameForVersion(int version) => 'schema_v$version.dart';

  static final _filenames = RegExp(r'(?:moor|drift)_schema_v(\d+)\.json');
  static final _dartfmt = DartFormatter();
  static const _prefix = '// GENERATED CODE, DO NOT EDIT BY HAND.';
}

extension on StringBuffer {
  void writeDartVersion(bool isNnbd) {
    writeln(isNnbd ? '//@dart=2.12' : '//@dart=2.9');
  }
}
