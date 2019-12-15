import 'dart:async';
import 'dart:io';

import 'package:moor_generator/src/analyzer/runner/results.dart';
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
    final analyzer = await cli.analyzer;
    final directory = Directory.current;
    print('Starting to scan in ${directory.path}...');

    final driver = analyzer.createAnalysisDriver(directory.path);

    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File) continue;

      final file = entity as File;
      if (p.extension(file.path) != '.dart') continue;

      print('scanning - $file');

      final parsed = await driver.waitFileParsed(entity.path);
      final result = parsed.currentResult as ParsedDartFile;

      if (result.dbAccessors.isNotEmpty) {
        final displayName = p.relative(file.path, from: directory.path);

        final names = result.dbAccessors
            .map((t) => t.declaration.fromClass.name)
            .join(', ');

        print('$displayName has moor databases or daos: $names');
      }
    }
  }
}
