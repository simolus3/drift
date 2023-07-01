import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../analysis/results/results.dart';
import '../cli.dart';

class IdentifyDatabases extends MoorCommand {
  IdentifyDatabases(DriftDevCli cli) : super(cli);

  @override
  String get description =>
      'Test for the analyzer - list all drift databases in a project';

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

      final result = await driver.analyzeElementsForPath(file.path);
      for (final analyzedElement in result.analysis.values) {
        final element = analyzedElement.result;

        if (element is BaseDriftAccessor) {
          final message = StringBuffer(
              'Found ${element.id.name} in ${element.id.libraryUri}!');

          if (element is DriftDatabase) {
            final daos =
                element.accessors.map((e) => e.ownType.toString()).join(', ');
            message
              ..writeln()
              ..write('Schema version: ${element.schemaVersion}, daos: $daos');
          }

          cli.logger.info(message);
        }
      }
    }
  }
}
