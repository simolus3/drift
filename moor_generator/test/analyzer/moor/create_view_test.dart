@Tags(['analyzer'])
import 'package:moor_generator/src/analyzer/errors.dart';
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

    expect(file.errors.errors, isEmpty);
  });

  test('view created from another view', () async {
    final state = TestState.withContent({
      'foo|lib/table.moor': '''
        CREATE TABLE t (id INTEGER NOT NULL PRIMARY KEY, name TEXT NOT NULL);
      ''',
      'foo|lib/view.moor': '''
        CREATE VIEW v AS
        SELECT id, name FROM t WHERE id % 2 = 0;
      ''',
      'foo|lib/a.moor': '''
        import 'view.moor';
        CREATE VIEW random_view AS
        SELECT name FROM v;
      ''',
    });

    final file = await state.analyze('package:foo/a.moor');
    final view = file.currentResult.declaredViews.single;
    expect(view.parserView.resolvedColumns.length, equals(1));
    final column = view.parserView.resolvedColumns.single;

    state.close();

    expect(column.type.type, BasicType.text);

    expect(file.errors.errors, isEmpty);
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
}
