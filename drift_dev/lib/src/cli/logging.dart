//@dart=2.9
import 'package:cli_util/cli_logging.dart' as cli;
import 'package:logging/logging.dart' as log;

void setupLogging({bool verbose = false, bool useAnsi}) {
  final ansi = cli.Ansi(useAnsi ?? cli.Ansi.terminalSupportsAnsi);
  final cliLogger = verbose
      ? cli.Logger.verbose(ansi: ansi)
      : cli.Logger.standard(ansi: ansi);

  log.Logger.root.onRecord.listen((rec) {
    final level = rec.level;
    final msgBuffer = StringBuffer();

    msgBuffer
      ..write(rec.level.name)
      ..write(': ')
      ..write(rec.message);

    if (rec.error != null) {
      msgBuffer
        ..write(rec.error)
        ..write('\n')
        ..write(rec.stackTrace);
    }

    if (level <= log.Level.CONFIG) {
      cliLogger.trace(msgBuffer.toString());
    } else if (level <= log.Level.INFO) {
      cliLogger.stdout(msgBuffer.toString());
    } else {
      cliLogger.stderr(msgBuffer.toString());
    }
  });
}
