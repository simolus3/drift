import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:moor_generator/src/plugin/plugin.dart';

void start(List<String> args, SendPort sendPort) {
  ServerPluginStarter(MoorPlugin(PhysicalResourceProvider.INSTANCE))
      .start(sendPort);
}
