import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/services/schema/schema_files.dart';
import 'package:path/path.dart';

import '../../cli.dart';

class DumpSchemaCommand extends Command {
  @override
  String get description => 'Export the entire table structure into a file';

  @override
  String get name => 'dump';

  @override
  String get invocation {
    return '${runner!.executableName} schema dump [arguments] <input> <output>';
  }

  final MoorCli cli;

  DumpSchemaCommand(this.cli) {
    argParser.addSeparator("It's recommended to run this commend from the "
        'directory containing your pubspec.yaml so that compiler options '
        'are respected.');
  }

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      usageException('Expected input and output files');
    }

    final driver = await cli.createMoorDriver();

    final absolute = File(rest[0]).absolute.path;
    final input = await driver.waitFileParsed(absolute);

    if (input == null || !input.isAnalyzed) {
      cli.exit('Unexpected error: The input file could not be analyzed');
    }

    final result = input.currentResult;
    if (result is! ParsedDartFile) {
      cli.exit('Input file is not a Dart file');
    }

    final db = result.declaredDatabases.single;
    final writer = SchemaWriter(db);

    var target = rest[1];
    // This command is most commonly used to write into
    // `<dir>/drift_schema_vx.json`. When we get a directory as a second arg,
    // try to infer the file name.
    if (await FileSystemEntity.isDirectory(target) ||
        !target.endsWith('.json')) {
      final version = db.schemaVersion;

      if (version == null) {
        // Couldn't read schema from database, so fail.
        usageException(
          'Target is a directory and the schema version could not be read from '
          'the database class. Please use a full filename (e.g. '
          '`$target/drift_schema_v3.json`)',
        );
      }

      target = join(target, 'drift_schema_v$version.json');
    }

    final file = File(target);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    await File(target).writeAsString(json.encode(writer.createSchemaJson()));
    print('Wrote to $target');
  }
}
