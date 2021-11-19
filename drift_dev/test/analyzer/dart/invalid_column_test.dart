@Tags(['analyzer'])
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late TestState state;

  setUpAll(() async {
    state = TestState.withContent({
      'foo|lib/main.dart': '''
        import 'package:drift/drift.dart';

        class HasInvalidColumn extends Table {
          IntColumn get id => integer().call();

          @override
          Set<Column> get primaryKey => {id};
        }
      ''',
    });

    await state.analyze('package:foo/main.dart');
  });

  tearDownAll(() => state.close());

  test('warns about invalid column', () {
    final file = state.file('package:foo/main.dart');
    final result = file.currentResult as ParsedDartFile;
    final table = result.declaredTables
        .singleWhere((t) => t.sqlName == 'has_invalid_column');

    expect(table.columns, isEmpty);

    file.expectDartError(
        contains('This getter does not create a valid column'), 'id');
    file.expectDartError(contains('Column not found'), 'id');
  });
}
