//@dart=2.9
import 'dart:isolate';

import 'package:analyzer_plugin/starter.dart';
import 'package:moor_generator/src/backends/plugin/plugin.dart';

void start(List<String> args, SendPort sendPort) {
  ServerPluginStarter(MoorPlugin.forProduction()).start(sendPort);
}
