import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../analysis/results/results.dart';
import '../../services/schema/schema_files.dart';
import 'schema/dump.dart';
import 'schema/export.dart';
import 'schema/generate_utils.dart';

import '../cli.dart';
import 'schema/steps.dart';

class SchemaCommand extends Command {
  @override
  String get description => 'Inspect or manage the schema of a drift database';

  @override
  String get name => 'schema';

  SchemaCommand(DriftDevCli cli) {
    addSubcommand(DumpSchemaCommand(cli));
    addSubcommand(GenerateUtilsCommand(cli));
    addSubcommand(WriteVersions(cli));
    addSubcommand(ExportSchemaCommand(cli));
  }
}

typedef AnalyzedDatabase = ({
  List<DriftElement> elements,
  int? schemaVersion,
  DriftDatabase? db
});

extension ExportSchema on DriftDevCli {
  /// Extracts available drift elements from a [dart] source file defining a
  /// drift database class.
  Future<AnalyzedDatabase> readElementsFromSource(File dart) async {
    final driver = await createAnalysisDriver();
    final input =
        await driver.driver.fullyAnalyze(driver.uriFromPath(dart.path));

    if (!input.isFullyAnalyzed) {
      this.exit('Unexpected error: The input file could not be analyzed');
    }

    final databases =
        input.analysis.values.map((e) => e.result).whereType<DriftDatabase>();

    if (databases.length != 1) {
      this.exit('Expected the input file to contain exactly one database.');
    }

    final result = input.fileAnalysis!;
    final databaseElement = databases.single;
    final db = result.resolvedDatabases[databaseElement.id]!;
    return (
      elements: db.availableElements,
      schemaVersion: databaseElement.schemaVersion,
      db: databaseElement,
    );
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
