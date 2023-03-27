@Tags(['skip_during_development', 'for_build_community_test'])
import 'package:build_verify/build_verify.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('build is up-to-date', () {
    return expectBuildClean(
      packageRelativeDirectory: 'drift',
      gitDiffPathArguments: ['test/generated'],
    );
  });
}
