@Tags(['analyzer'])

import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('warns about invalid column', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.dart': '''
        import 'package:drift/drift.dart';

        class HasInvalidColumn extends Table {
          IntColumn get id => integer().call();

          @override
          Set<Column> get primaryKey => {id};
        }
      ''',
    });

    final file =
        await backend.driver.fullyAnalyze(Uri.parse('package:a/main.dart'));
    final table = file.analyzedElements.single as DriftTable;

    expect(table.schemaName, 'has_invalid_column');
    expect(table.columns, isEmpty);

    expect(
      file.allErrors,
      containsAll(
        [
          isDriftError(contains('This getter does not create a valid column'))
              .withSpan('id'),
          isDriftError(contains('Column not found')).withSpan('id'),
        ],
      ),
    );
  });
}
