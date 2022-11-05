import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:drift_dev/src/cli/project.dart';
import 'package:logging/logging.dart';

import '../backends/analyzer_context_backend.dart';
import 'commands/analyze.dart';
import 'commands/identify_databases.dart';
//import 'commands/migrate.dart';
//import 'commands/schema.dart';
import 'logging.dart';

Future run(List<String> args) async {
  final cli = MoorCli();
  try {
    return await cli.run(args);
  } on UsageException catch (e) {
    print(e);
  }
}

class MoorCli {
  Logger get logger => Logger.root;
  late final CommandRunner _runner;
  late final MoorProject project;

  bool verbose = false;

  MoorCli() {
    _runner = CommandRunner(
      'dart run drift_dev',
      'CLI utilities for the drift package, currently in an experimental state.',
      usageLineLength: 80,
    )
      ..addCommand(AnalyzeCommand(this))
      ..addCommand(IdentifyDatabases(this));
//      ..addCommand(SchemaCommand(this))
//      ..addCommand(MigrateCommand(this));

    _runner.argParser
        .addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
    _runner.argParser.addFlag(
      'ansi',
      abbr: 'a',
      help: 'Whether to output colorful logs. Attempts to check whether this '
          'is supported by the terminal by default.',
    );
  }

  Future<PhysicalDriftDriver> createMoorDriver() async {
    return AnalysisContextBackend.createDriver(
      options: project.moorOptions,
      projectDirectory: project.directory.path,
    );
  }

  Future<void> run(Iterable<String> args) async {
    final results = _runner.parse(args);
    verbose = results['verbose'] as bool;

    setupLogging(verbose: verbose);
    project = await MoorProject.readFromDir(Directory.current);

    await _runner.runCommand(results);
  }

  Never exit(String message) {
    throw FatalToolError(message);
  }
}

abstract class MoorCommand extends Command {
  final MoorCli cli;

  MoorCommand(this.cli);
}

class FatalToolError implements Exception {
  final String message;

  FatalToolError(this.message);

  @override
  String toString() {
    return 'Fatal error: $message';
  }
}
