import 'dart:convert';
import 'dart:io';

import 'package:coverage/coverage.dart';
import 'package:path/path.dart';

void main() async {
  final tests = join(File.fromUri(Platform.script).parent.path, 'tester.dart');
  final coverage = await runAndCollect(tests, onExit: true, printOutput: true);

  File('coverage.json').writeAsStringSync(json.encode(coverage));
}
