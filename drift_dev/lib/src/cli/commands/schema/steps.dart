import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';

import '../../../analysis/options.dart';
import '../../../analysis/results/element.dart';
import '../../../writer/import_manager.dart';
import '../../../writer/schema_version_writer.dart';
import '../../../writer/writer.dart';
import '../../cli.dart';
import '../schema.dart';

class WriteVersions extends Command {
  final DriftDevCli cli;

  WriteVersions(this.cli);

  @override
  String get name => 'steps';

  @override
  String get description =>
      'Write a Dart file helping with incremental migrations between schema versions.';

  @override
  String get invocation {
    return '${runner!.executableName} schema steps <schema directory> <output file>';
  }

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      usageException('Expected input and output directories');
    }

    final inputDirectory = Directory(rest[0]);
    final outputFile = File(rest[1]);
    final outputDirectory = outputFile.parent;

    if (!await inputDirectory.exists()) {
      cli.exit('The provided input directory does not exist.');
    }

    if (!await outputDirectory.exists()) {
      await outputDirectory.create();
    }

    final imports = LibraryImportManager();
    final writer = Writer(
      const DriftOptions.defaults(),
      generationOptions: GenerationOptions(imports: imports),
    );
    imports.linkToWriter(writer);

    final schema = await parseSchema(inputDirectory);
    final byVersion = [
      for (final MapEntry(key: version, value: schema) in schema.entries)
        SchemaVersion(
          version,
          schema.schema.whereType<DriftSchemaElement>().toList(),
          schema.options,
        ),
    ];
    byVersion.sortBy<num>((s) => s.version);

    writer.leaf().write("import 'package:drift/drift.dart';");
    SchemaVersionWriter(byVersion, writer.child()).write();

    var code = writer.writeGenerated();
    try {
      code = DartFormatter().format(code);
    } on FormatterException {
      // Ignore. Probably a bug in drift_dev, the user will notice.
    }

    await outputFile.writeAsString(code);
  }
}
