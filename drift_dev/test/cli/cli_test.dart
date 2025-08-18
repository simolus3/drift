import 'package:drift_dev/src/cli/cli.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('exits with error when no command is selected', () async {
    final project = await TestDriftProject.create();

    expect(() async {
      await project.runDriftCli([]);
    }, throwsA(ExitCodeException.usage()));
  });
}
