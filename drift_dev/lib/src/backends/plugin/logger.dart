import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:logging/logging.dart';

import 'plugin.dart';

var _initialized = false;

/// Configures the [Logger.root] logger to work with the plugin. Sadly, we don't
/// really have a way to view [print] outputs from plugins, so we use the
/// diagnostics notification for that.
void setupLogger(DriftPlugin plugin) {
  assert(!_initialized, 'Logger initialized multiple times');

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    if (rec.level >= Level.WARNING) {
      // when we send analysis errors, some tooling prompts users to create an
      // issue on the Dart SDK repo for that. We're responsible for the problem
      // though, so tell the user to not annoy the Dart Team with this.
      final message = 'PLEASE DO NOT REPORT THIS ON dart-lang/sdk! '
          'This should be reported via https://github.com/simolus3/drift/issues/new '
          'instead. Message was ${rec.message}, error ${rec.error}';

      final error =
          PluginErrorParams(false, message, rec.stackTrace.toString());

      plugin.channel.sendNotification(error.toNotification());
    }

    print('${rec.level.name}: ${rec.message}');
    if (rec.error != null) {
      print('${rec.error}: \n${rec.stackTrace}');
    }
  });
  _initialized = true;
}
