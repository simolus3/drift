import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/services/schema/schema_files.dart';

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

    await File(rest[1]).writeAsString(json.encode(writer.createSchemaJson()));
  }
}
