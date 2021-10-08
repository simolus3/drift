//@dart=2.9
@Tags(['analyzer'])
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/model/table.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('view created', () async {
    final state = TestState.withContent({
      'foo|lib/table.moor': '''
        CREATE TABLE t (id INTEGER NOT NULL PRIMARY KEY, name TEXT NOT NULL);
      ''',
      'foo|lib/a.moor': '''
        import 'table.moor';
        CREATE VIEW random_view AS
        SELECT name FROM t WHERE id % 2 = 0;
      ''',
    });

    final file = await state.analyze('package:foo/a.moor');
    final view = file.currentResult.declaredViews.single;
    expect(view.parserView.resolvedColumns.length, equals(1));
    final column = view.parserView.resolvedColumns.single;

    state.close();

    expect(column.type.type, BasicType.text);
    expect(view.references,
        contains(isA<MoorTable>().having((t) => t.sqlName, 'sqlName', 't')));
    expect(file.errors.errors, isEmpty);
  });

  test('view created from another view', () async {
    final state = TestState.withContent({
      'foo|lib/table.moor': '''
        CREATE TABLE t (id INTEGER NOT NULL PRIMARY KEY, name TEXT NOT NULL);
      ''',
      'foo|lib/a.moor': '''
        import 'table.moor';

        CREATE VIEW parent_view AS
        SELECT id, name FROM t WHERE id % 2 = 0;

        CREATE VIEW child_view AS
        SELECT name FROM parent_view;
      ''',
    });

    final file = await state.analyze('package:foo/a.moor');
    final parentView = file.currentResult.declaredViews
        .singleWhere((element) => element.name == 'parent_view');
    final childView = file.currentResult.declaredViews
        .singleWhere((element) => element.name == 'child_view');
    expect(parentView.parserView.resolvedColumns.length, equals(2));
    expect(childView.parserView.resolvedColumns.length, equals(1));
    final column = childView.parserView.resolvedColumns.single;

    state.close();

    expect(parentView.references.map((e) => e.displayName), ['t']);
    expect(childView.references, [parentView]);
    expect(
        childView.transitiveTableReferences.map((e) => e.displayName), ['t']);

    expect(file.errors.errors, isEmpty);
    expect(column.type.type, BasicType.text);
  });

  test('view without table', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
        CREATE VIEW random_view AS
        SELECT name FROM t WHERE id % 2 = 0;
      ''',
    });

    final file = await state.analyze('package:foo/a.moor');

    state.close();

    expect(
        file.errors.errors,
        contains(isA<MoorError>().having(
          (e) => e.message,
          'message',
          contains('Could not find t.'),
        )));
  });

  test('does not allow nested columns', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
        CREATE TABLE foo (bar INTEGER NOT NULL PRIMARY KEY);
      
        CREATE VIEW v AS SELECT foo.** FROM foo;
      ''',
    });

    final file = await state.analyze('package:foo/a.moor');

    state.close();

    expect(
        file.errors.errors,
        contains(isA<MoorError>().having(
          (e) => e.message,
          'message',
          contains('Nested star columns may only appear in a top-level select '
              'query.'),
        )));
  });
}
