import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grinder/grinder_sdk.dart';
import 'package:coverage/coverage.dart';
import 'package:path/path.dart';

import 'format_coverage.dart' as fc;

const int _vmPort = 9876;

Future<void> main(List<String> args) async {
  // First, generate the build script, see
  // https://github.com/dart-lang/build/blob/3208cfe94c475ed3e1ec44c227aadaddaeac263d/build_runner/bin/build_runner.dart#L65
  Pub.run('build_runner', arguments: ['generate-build-script']);

  // Start coverage collection (resume isolates, don't wait for pause, collect
  // when isolates exit).
  final collectorFuture =
      collect(Uri.parse('http://localhost:$_vmPort'), true, false, true);

  // Next, run the test script in another dart process that has the vm services
  // enabled.
  final tests = join(File.fromUri(Platform.script).parent.path, 'tester.dart');
  // not using Dart.run because that only prints to stdout after the process has
  // completed.
  await Dart.runAsync(tests,
      vmArgs: ['--enable-vm-service=$_vmPort', '--pause-isolates-on-exit']);

  File('coverage.json').writeAsStringSync(json.encode(await collectorFuture));

  print('formatting to .lcov format');
  await fc.main();
}
