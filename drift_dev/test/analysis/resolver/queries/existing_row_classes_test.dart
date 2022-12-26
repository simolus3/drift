import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('recognizes existing row classes', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 'hello world', 2;
''',
      'a|lib/a.dart': '''
class MyRow {
  final String a;
  final int b;

  MyRow(this.a, this.b);
}
''',
    });

    final uri = Uri.parse('package:a/a.drift');
    final file = await state.driver.resolveElements(uri);

    state.expectNoErrors();
    final query = file.analyzedElements.single as DefinedSqlQuery;
    expect(query.resultClassName, isNull);
    expect(query.existingDartType?.getDisplayString(withNullability: true),
        'MyRow');
  });

  test("warns if existing row classes don't exist", () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 'hello world', 2;
''',
    });

    final file = await state.analyze('package:a/a.drift');
    expect(file.allErrors, [
      isDriftError(contains('are you missing an import?'))
          .withSpan('WITH MyRow')
    ]);
  });
}
