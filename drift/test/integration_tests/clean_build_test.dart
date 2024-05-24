@Tags(['skip_during_development', 'for_build_community_test'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:build_verify/build_verify.dart';
import 'package:test/test.dart';

void main() {
  test('build is up-to-date', () async {
    // Running `build_runner build -d` while other tests are loading
    // concurrently can break things as source files are being regenerated.
    // For drift's CI, we're running the build before starting tests, so there's
    // no point in building again and we can just diff right away. For build
    // community tests, we should use build_verify but we've also disabled
    // test concurrency in that setup.
    final didRunBuildRunner =
        Platform.environment['DID_RUN_BUILD_RUNNER'] == '1';

    if (didRunBuildRunner) {
      print('Simple diff as build runner already ran');
      final process = await Process.start('git', [
        'diff',
        '--relative',
        'test/generated',
      ]);

      final stdoutContent = <String>[];
      await (
        process.stdout
            .transform(const SystemEncoding().decoder)
            .transform(const LineSplitter())
            .forEach(stdoutContent.add),
        process.exitCode
      ).wait;

      expect(stdoutContent, isEmpty);
    } else {
      await expectBuildClean(
        packageRelativeDirectory: 'drift',
        gitDiffPathArguments: ['test/generated'],
      );
    }
  });
}
