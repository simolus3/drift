import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../analysis/results/results.dart';
import '../../services/schema/schema_files.dart';
import 'schema/dump.dart';
import 'schema/generate_utils.dart';

import '../cli.dart';
import 'schema/steps.dart';

class SchemaCommand extends Command {
  @override
  String get description => 'Inspect or manage the schema of a moor database';

  @override
  String get name => 'schema';

  SchemaCommand(DriftDevCli cli) {
    addSubcommand(DumpSchemaCommand(cli));
    addSubcommand(GenerateUtilsCommand(cli));
    addSubcommand(WriteVersions(cli));
  }
}

class ExportedSchema {
  final List<DriftElement> schema;
  final Map<String, Object?> options;

  ExportedSchema(this.schema, this.options);
}

final _filenames = RegExp(r'(?:moor|drift)_schema_v(\d+)\.json');

Future<Map<int, ExportedSchema>> parseSchema(Directory directory) async {
  final results = <int, ExportedSchema>{};

  await for (final entity in directory.list()) {
    final basename = p.basename(entity.path);
    final match = _filenames.firstMatch(basename);

    if (match == null || entity is! File) continue;

    final version = int.parse(match.group(1)!);
    final rawData = json.decode(await entity.readAsString());

    final schema = SchemaReader.readJson(rawData as Map<String, dynamic>);
    results[version] = ExportedSchema(schema.entities.toList(), schema.options);
  }

  return results;
}
