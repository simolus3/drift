import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli.dart';

class AnalyzeCommand extends MoorCommand {
  AnalyzeCommand(MoorCli cli) : super(cli);

  @override
  String get description => 'Analyze and lint moor files';

  @override
  String get name => 'analyze';

  @override
  Future<void> run() async {
    final driver = await cli.createMoorDriver();

    var errorCount = 0;

    await for (final file in cli.project.sourceFiles) {
      if (p.extension(file.path) != '.moor') continue;

      cli.logger.fine('Analyzing $file');

      final parsed = await driver.waitFileParsed(file.path);

      if (parsed.errors.errors.isNotEmpty) {
        cli.logger.warning('For file ${p.relative(file.path)}:');
        for (final error in parsed.errors.errors) {
          error.writeDescription(cli.logger.warning);
          errorCount++;
        }
      }
    }

    if (errorCount == 0) {
      cli.logger.info('No errrors found');
    } else {
      cli.logger.info('Found $errorCount errors or problems');
      exit(1);
    }
  }
}
