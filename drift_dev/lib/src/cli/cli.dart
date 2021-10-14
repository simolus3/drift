//@dart=2.9
import 'dart:async';
import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/command_runner.dart';
import 'package:drift_dev/src/backends/common/driver.dart';
import 'package:drift_dev/src/cli/project.dart';
import 'package:logging/logging.dart';

import 'commands/analyze.dart';
import 'commands/identify_databases.dart';
import 'commands/migrate.dart';
import 'commands/schema.dart';
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
  CommandRunner _runner;
  MoorProject project;

  bool verbose;

  MoorCli() {
    _runner = CommandRunner(
      'pub run moor_generator',
      'CLI utilities for the moor package, currently in an experimental state.',
      usageLineLength: 80,
    )
      ..addCommand(AnalyzeCommand(this))
      ..addCommand(IdentifyDatabases(this))
      ..addCommand(SchemaCommand(this))
      ..addCommand(MigrateCommand(this));

    _runner.argParser
        .addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
    _runner.argParser.addFlag(
      'ansi',
      abbr: 'a',
      help: 'Whether to output colorful logs. Attempts to check whether this '
          'is supported by the terminal by default.',
    );
  }

  Future<MoorDriver> createMoorDriver() async {
    return MoorDriver(PhysicalResourceProvider.INSTANCE,
        options: project.moorOptions, contextRoot: project.directory.path);
  }

  Future<void> run(Iterable<String> args) async {
    final results = _runner.parse(args);
    verbose = results['verbose'] as bool;

    setupLogging(verbose: verbose);
    project = await MoorProject.readFromDir(Directory.current);

    await _runner.runCommand(results);
  }

  void exit(String message) {
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
