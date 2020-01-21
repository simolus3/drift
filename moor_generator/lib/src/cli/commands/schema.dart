import 'package:args/command_runner.dart';
import 'package:moor_generator/src/cli/commands/schema/dump.dart';

import '../cli.dart';

class SchemaCommand extends Command {
  @override
  String get description => 'Inspect or manage the schema of a moor database';

  @override
  String get name => 'schema';

  SchemaCommand(MoorCli cli) {
    addSubcommand(DumpSchemaCommand(cli));
  }
}
