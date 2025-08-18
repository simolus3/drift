import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:drift_dev/src/cli/commands/make_migrations.dart';
import 'package:drift_dev/src/cli/project.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../backends/analyzer_context_backend.dart';
import 'commands/analyze.dart';
import 'commands/identify_databases.dart';
import 'commands/migrate.dart';
import 'commands/schema.dart';
import 'logging.dart';

Future<void> run(List<String> args) async {
  final cli = DriftDevCli();
  try {
    return await cli.run(args);
  } on UsageException catch (e) {
    print(e);
    throw ExitCodeException();
  }
}

class DriftDevCli {
  Logger get logger => Logger.root;
  late final CommandRunner _runner;
  late final DriftProject project;

  bool verbose = false;

  DriftDevCli() {
    _runner = CommandRunner(
      'dart run drift_dev',
      'CLI utilities for the drift package, currently in an experimental state.',
      usageLineLength: 80,
    )
      ..addCommand(AnalyzeCommand(this))
      ..addCommand(IdentifyDatabases(this))
      ..addCommand(SchemaCommand(this))
      ..addCommand(MigrateCommand(this))
      ..addCommand(MakeMigrationCommand(this));

    _runner.argParser
        .addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
    _runner.argParser.addFlag(
      'ansi',
      abbr: 'a',
      help: 'Whether to output colorful logs. Attempts to check whether this '
          'is supported by the terminal by default.',
    );
  }

  Future<PhysicalDriftDriver> createAnalysisDriver() async {
    return AnalysisContextBackend.createDriver(
      options: project.options,
      projectDirectory: p.normalize(project.directory.path),
    );
  }

  Future<void> run(Iterable<String> args) async {
    final results = _runner.parse(args);
    verbose = results['verbose'] as bool;

    setupLogging(verbose: verbose);
    project = await DriftProject.readFromDir(Directory.current);

    await _runner.runCommand(results);
    if (results.command == null) {
      throw ExitCodeException.usage();
    }
  }

  Never exit(String message) {
    throw FatalToolError(message);
  }
}

abstract class DriftCommand extends Command {
  final DriftDevCli cli;

  DriftCommand(this.cli);
}

class FatalToolError implements Exception {
  final String message;

  FatalToolError(this.message);

  @override
  String toString() {
    return 'Fatal error: $message';
  }
}

/// An exception that will make [run] call [exit] with the given [code].
///
/// This is an exception so that it can be caught and expected for tests.
final class ExitCodeException implements Exception {
  final int code;

  ExitCodeException([this.code = 1]);

  ExitCodeException.usage() : code = 64;

  @override
  int get hashCode => Object.hash(ExitCodeException, code);

  @override
  bool operator ==(Object other) {
    return other is ExitCodeException && other.code == code;
  }
}
