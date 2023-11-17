import 'dart:io';

import '../cli.dart';

class AnalyzeCommand extends MoorCommand {
  AnalyzeCommand(super.cli);

  @override
  String get description => 'Analyze and lint drift database code';

  @override
  String get name => 'analyze';

  @override
  Future<void> run() async {
    final driver = await cli.createMoorDriver();

    var errorCount = 0;

    await for (final file in cli.project.sourceFiles) {
      cli.logger.fine('Analyzing $file');

      final results =
          await driver.driver.fullyAnalyze(driver.uriFromPath(file.path));

      for (final error in results.allErrors) {
        cli.logger.warning(error.toString());
        errorCount++;
      }
    }

    if (errorCount == 0) {
      cli.logger.info('No errors found');
    } else {
      cli.logger.info('Found $errorCount errors or problems');
      exit(1);
    }
  }
}
