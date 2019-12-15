import 'dart:async';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/command_runner.dart';
import 'package:moor_generator/src/backends/standalone.dart';
import 'package:moor_generator/src/cli/commands/debug_plugin.dart';

import 'commands/identify_databases.dart';

Future run(List<String> args) {
  final cli = MoorCli();
  return cli._runner.run(args);
}

class MoorCli {
  final StandaloneMoorAnalyzer _analyzer;
  final Completer<void> _analyzerReadyCompleter = Completer();

  CommandRunner _runner;

  Future<StandaloneMoorAnalyzer> get analyzer async {
    await _analyzerReadyCompleter.future;
    return _analyzer;
  }

  MoorCli()
      : _analyzer = StandaloneMoorAnalyzer(PhysicalResourceProvider.INSTANCE) {
    _runner = CommandRunner(
      'pub run moor_generator',
      'CLI utilities for the moor package, currently in an experimental state.',
    )
      ..addCommand(IdentifyDatabases(this))
      ..addCommand(DebugPluginCommand(this));

    _analyzerReadyCompleter.complete(_analyzer.init());
  }
}

abstract class MoorCommand extends Command {
  final MoorCli cli;

  MoorCommand(this.cli);
}
