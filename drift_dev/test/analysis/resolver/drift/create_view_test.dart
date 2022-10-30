@Tags(['analyzer'])
import 'package:drift/drift.dart' as drift;
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('view created', () async {
    final state = TestBackend.inTest({
      'foo|lib/table.drift': '''
        CREATE TABLE t (id INTEGER NOT NULL PRIMARY KEY, name TEXT NOT NULL);
      ''',
      'foo|lib/a.drift': '''
        import 'table.drift';
        CREATE VIEW random_view AS
        SELECT name FROM t WHERE id % 2 = 0;
      ''',
    });

    final file = await state.analyze('package:foo/a.drift');
    final view = file.analyzedElements.single as DriftView;

    expect(view.columns, [
      isA<DriftColumn>()
          .having((e) => e.sqlType, 'sqlType', drift.DriftSqlType.string)
    ]);

    expect(view.references,
        [isA<DriftTable>().having((t) => t.schemaName, 'schemaName', 't')]);

    state.expectNoErrors();
  });

  test('view created from another view', () async {
    final state = TestBackend.inTest({
      'foo|lib/table.drift': '''
        CREATE TABLE t (id INTEGER NOT NULL PRIMARY KEY, name TEXT NOT NULL);
      ''',
      'foo|lib/a.drift': '''
        import 'table.drift';

        CREATE VIEW parent_view AS
        SELECT id, name FROM t WHERE id % 2 = 0;

        CREATE VIEW child_view AS
        SELECT name FROM parent_view;
      ''',
    });

    final file = await state.analyze('package:foo/a.drift');
    final parentView =
        file.analysis[file.id('parent_view')]!.result as DriftView;
    final childView = file.analysis[file.id('child_view')]!.result as DriftView;

    expect(parentView.columns, hasLength(2));
    expect(childView.columns, [
      isA<DriftColumn>()
          .having((e) => e.sqlType, 'sqlType', drift.DriftSqlType.string)
    ]);

    expect(parentView.references.map((e) => e.id.name), ['t']);
    expect(childView.references, [parentView]);
    expect(childView.transitiveTableReferences.map((e) => e.schemaName), ['t']);

    state.expectNoErrors();
  });

  test('view without table', () async {
    final state = TestBackend.inTest({
      'foo|lib/a.drift': '''
        CREATE VIEW random_view AS
        SELECT name FROM t WHERE id % 2 = 0;
      ''',
    });

    final file = await state.analyze('package:foo/a.drift');

    expect(
        file.allErrors, contains(isDriftError(contains('Could not find t'))));
  });

  test('does not allow nested columns', () async {
    final state = TestBackend.inTest({
      'foo|lib/a.drift': '''
        CREATE TABLE foo (bar INTEGER NOT NULL PRIMARY KEY);

        CREATE VIEW v AS SELECT foo.** FROM foo;
      ''',
    });

    final file = await state.analyze('package:foo/a.drift');

    expect(file.allErrors, [
      isDriftError(
          contains('Nested star columns may only appear in a top-level select '
              'query.'))
    ]);
  });
}
