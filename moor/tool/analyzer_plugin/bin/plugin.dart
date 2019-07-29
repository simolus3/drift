import 'dart:isolate';

import 'package:moor_generator/plugin.dart';

void main(List<String> args, SendPort sendPort) {
  start(args, sendPort);
}
