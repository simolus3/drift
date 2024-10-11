import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  // Test the linter_test.dart file
  test('linter', () async {
    final workingDir = p.join(p.current, 'test/linter_test/pkg');
    expect(
        await Process.run('dart', ['pub', 'get'], workingDirectory: workingDir)
            .then((v) => v.exitCode),
        0);
    expect(
        await Process.run('custom_lint', ['--fatal-infos', '--fatal-warnings'],
                workingDirectory: workingDir)
            .then((v) => v.exitCode),
        0);
  });
}
