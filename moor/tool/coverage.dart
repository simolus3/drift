import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grinder/grinder_sdk.dart';
import 'package:coverage/coverage.dart';
import 'package:path/path.dart';

Future<void> main(List<String> args) async {
  Pub.run('build_runner', arguments: ['build', '--delete-conflicting-outputs']);

  // Next, run the test script in another dart process that has the vm services
  // enabled.
  final tests = join(File.fromUri(Platform.script).parent.path, 'tester.dart');
  final coverage = await runAndCollect(tests, onExit: true, printOutput: true);

  File('coverage.json').writeAsStringSync(json.encode(coverage));
}
