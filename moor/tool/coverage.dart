import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grinder/grinder_sdk.dart';
import 'package:coverage/coverage.dart';
import 'package:path/path.dart';

import 'format_coverage.dart' as fc;

Future<void> main(List<String> args) async {
  // First, generate the build script, see
  // https://github.com/dart-lang/build/blob/3208cfe94c475ed3e1ec44c227aadaddaeac263d/build_runner/bin/build_runner.dart#L65
  Pub.run('build_runner', arguments: ['generate-build-script']);

  // Next, run the test script in another dart process that has the vm services
  // enabled.
  final tests = join(File.fromUri(Platform.script).parent.path, 'tester.dart');
  final coverage = await runAndCollect(tests, onExit: true, printOutput: true);

  File('coverage.json').writeAsStringSync(json.encode(coverage));

  print('formatting to .lcov format');
  await fc.main();
}
