import 'dart:async';
import 'dart:io';

import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:path/path.dart' as p;

import '../cli.dart';

class IdentifyDatabases extends MoorCommand {
  IdentifyDatabases(MoorCli cli) : super(cli);

  @override
  String get description =>
      'Test for the analyzer - list all moor databases in a project';

  @override
  String get name => 'identify-databases';

  @override
  Future run() async {
    final directory = Directory.current;
    print('Starting to scan in ${directory.path}...');

    final driver = await cli.createMoorDriver();

    await for (final file in cli.project.sourceFiles) {
      if (p.extension(file.path) != '.dart') continue;

      cli.logger.fine('Scanning $file');

      final parsed = (await driver.waitFileParsed(file.path))!;
      final result = parsed.currentResult;

      // might be a `part of` file...
      if (result is! ParsedDartFile) continue;

      if (result.dbAccessors.isNotEmpty) {
        final displayName = p.relative(file.path, from: directory.path);

        final names = result.dbAccessors
            .map((t) => t.declaration!.fromClass.name)
            .join(', ');

        cli.logger.info('$displayName has moor databases or daos: $names');
      }
    }
  }
}
