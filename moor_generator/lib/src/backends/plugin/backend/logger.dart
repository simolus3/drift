import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:logging/logging.dart';
import 'package:moor_generator/src/backends/plugin/plugin.dart';

var _initialized = false;

/// Configures the [Logger.root] logger to work with the plugin. Sadly, we don't
/// really have a way to view [print] outputs from plugins, so we use the
/// diagnostics notification for that.
void setupLogger(MoorPlugin plugin) {
  assert(!_initialized, 'Logger initialized multiple times');

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    if (rec.level >= Level.INFO) {
      final isFatal = rec.level > Level.WARNING;
      final error =
          PluginErrorParams(isFatal, rec.message, rec.stackTrace.toString());

      plugin.channel.sendNotification(error.toNotification());
    }
  });
  _initialized = true;
}
