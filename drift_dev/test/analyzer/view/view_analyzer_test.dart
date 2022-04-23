import 'package:drift_dev/src/model/model.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('picks valid Dart names', () async {
    final testState = TestState.withContent({
      'a|lib/a.drift': '''
CREATE VIEW IF NOT EXISTS repro AS
  SELECT 1,
         2 AS "1",
         3 AS "a + b",
         4 AS foo_bar_baz
;
''',
    });
    addTearDown(testState.close);

    final file = await testState.analyze('package:a/a.drift');
    expect(file.errors.errors, isEmpty);

    final view = file.currentResult!.declaredEntities.single as MoorView;
    expect(view.columns.map((e) => e.dartGetterName), [
      'empty', // 1
      'empty1', // 2 AS "1"
      'ab', // AS "a + b"
      'fooBarBaz', // fooBarBaz
    ]);
  });
}
