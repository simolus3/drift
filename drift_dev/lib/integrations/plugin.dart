import 'dart:isolate';

import 'package:analyzer_plugin/starter.dart';
import 'package:drift_dev/src/backends/plugin/plugin.dart';

void start(List<String> args, SendPort sendPort) {
  ServerPluginStarter(MoorPlugin.forProduction()).start(sendPort);
}
