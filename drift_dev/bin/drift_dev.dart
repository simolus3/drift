import 'dart:io';

import 'package:drift_dev/src/cli/cli.dart' as cli;

Future<void> main(List<String> args) async {
  try {
    await cli.run(args);
  } on cli.ExitCodeException catch (e) {
    exit(e.code);
  }
}
