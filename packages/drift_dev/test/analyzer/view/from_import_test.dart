import 'package:test/test.dart';

import '../utils.dart';

void main() {
  // Regression test for https://github.com/simolus3/moor/issues/1639
  test('imported views are analyzed', () async {
    final testState = TestState.withContent({
      'a|lib/imported.drift': '''
CREATE TABLE a (
  b TEXT NOT NULL
);

CREATE VIEW my_view AS SELECT * FROM a;
''',
      'a|lib/main.drift': '''
import 'imported.drift';

query: SELECT * FROM my_view;
''',
    });
    addTearDown(testState.close);

    final file = await testState.analyze('package:a/main.drift');
    expect(file.errors.errors, isEmpty);
  });
}
