@Tags(['analyzer'])
import 'package:drift/drift.dart' as drift;
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
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
      isA<DriftColumn>().having(
          (e) => e.sqlType.builtin, 'sqlType', drift.DriftSqlType.string)
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
      isA<DriftColumn>().having(
          (e) => e.sqlType.builtin, 'sqlType', drift.DriftSqlType.string)
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

  test('imported views are analyzed', () async {
    // Regression test for https://github.com/simolus3/drift/issues/1639

    final testState = TestBackend.inTest({
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

    final file = await testState.analyze('package:a/main.drift');
    testState.expectNoErrors();

    expect(file.analysis, hasLength(1));
  });

  test('picks valid Dart names for columns', () async {
    final testState = TestBackend.inTest({
      'a|lib/a.drift': '''
CREATE VIEW IF NOT EXISTS repro AS
  SELECT 1,
         2 AS "1",
         3 AS "a + b",
         4 AS foo_bar_baz
;
''',
    });

    final file = await testState.analyze('package:a/a.drift');
    expect(file.allErrors, isEmpty);

    final view = file.analyzedElements.single as DriftView;
    expect(view.columns.map((e) => e.nameInDart), [
      'empty', // 1
      'empty1', // 2 AS "1"
      'ab', // AS "a + b"
      'fooBarBaz', // fooBarBaz
    ]);
  });

  test('copies type converter from table', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'converter.dart';

CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY,
  foo INTEGER NOT NULL MAPPED BY `createConverter()`
);

CREATE VIEW foos AS SELECT foo FROM users;
''',
      'a|lib/converter.dart': '''
import 'package:drift/drift.dart';

TypeConverter<Object, int> createConverter() => throw UnimplementedError();
''',
    });

    final state = await backend.analyze('package:a/a.drift');
    backend.expectNoErrors();

    final table = state.analysis[state.id('users')]!.result as DriftTable;
    final tableColumn = table.columnBySqlName['foo'];

    final view = state.analysis[state.id('foos')]!.result as DriftView;
    final column = view.columns.single;

    expect(
      column.typeConverter,
      isA<AppliedTypeConverter>()
          .having(
              (e) => e.expression.toString(), 'expression', 'createConverter()')
          .having((e) => e.owningColumn, 'owningColumn', tableColumn),
    );
  });

  test('can declare type converter on view column', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'converter.dart';

CREATE VIEW v AS SELECT 1 MAPPED BY `createConverter()` AS r;
''',
      'a|lib/converter.dart': '''
import 'package:drift/drift.dart';

TypeConverter<Object, int> createConverter() => throw UnimplementedError();
''',
    });

    final state = await backend.analyze('package:a/a.drift');
    backend.expectNoErrors();

    final view = state.analyzedElements.single as DriftView;
    final column = view.columns.single;

    expect(
      column.typeConverter,
      isA<AppliedTypeConverter>()
          .having(
              (e) => e.expression.toString(), 'expression', 'createConverter()')
          .having((e) => e.owningColumn, 'owningColumn', column),
    );

    expect(
      view.source,
      isA<SqlViewSource>().having(
        (e) => e.sqlCreateViewStmt,
        'sqlCreateViewStmt',
        'CREATE VIEW v AS SELECT 1 AS r;',
      ),
    );
  });

  test('supports enum columns', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'enums.dart';

CREATE VIEW foo AS SELECT
  1 AS c1,
  CAST(1 AS ENUM(MyEnum)) AS c2,
  CAST('foo' AS ENUMNAME(MyEnum)) AS c3;
''',
      'a|lib/enums.dart': '''
enum MyEnum {
  foo, bar
}
''',
    });

    final state = await backend.analyze('package:a/a.drift');
    backend.expectNoErrors();

    final view = state.analyzedElements.single as DriftView;
    final c1 = view.columns[0];
    final c2 = view.columns[1];
    final c3 = view.columns[2];

    expect(c1.typeConverter, isNull);
    expect(
      c2.typeConverter,
      isA<AppliedTypeConverter>()
          .having((e) => e.isDriftEnumTypeConverter, 'isDriftEnumTypeConverter',
              isTrue)
          .having((e) => e.owningColumn, 'owningColumn', c2),
    );
    expect(
      c3.typeConverter,
      isA<AppliedTypeConverter>()
          .having((e) => e.isDriftEnumTypeConverter, 'isDriftEnumTypeConverter',
              isTrue)
          .having((e) => e.owningColumn, 'owningColumn', c3),
    );

    expect(
      view.source,
      isA<SqlViewSource>().having(
        (e) => e.sqlCreateViewStmt,
        'sqlCreateViewStmt',
        "CREATE VIEW foo AS SELECT 1 AS c1, CAST(1 AS INT) AS c2, CAST('foo' AS TEXT) AS c3;",
      ),
    );
  });

  group('desugars cast', () {
    Future<void> expectView(
      String definition,
      drift.DriftSqlType expectedType,
      String expectedSql,
      DriftOptions options,
    ) async {
      final backend = TestBackend.inTest(
        {'a|lib/a.drift': definition},
        options: options,
      );
      final state = await backend.analyze('package:a/a.drift');
      backend.expectNoErrors();

      final view = state.analyzedElements.single as DriftView;
      final column = view.columns.single;

      expect(column.sqlType.builtin, expectedType);
      expect(
        view.source,
        isA<SqlViewSource>().having(
          (e) => e.sqlCreateViewStmt,
          'sqlCreateViewStmt',
          expectedSql,
        ),
      );
    }

    test('to boolean', () async {
      await expectView(
        'CREATE VIEW x AS SELECT CAST(1 AS BOOLEAN) AS a;',
        drift.DriftSqlType.bool,
        'CREATE VIEW x AS SELECT CAST(1 AS INT) AS a;',
        const DriftOptions.defaults(),
      );
    });

    test('to datetime as int', () async {
      await expectView(
        'CREATE VIEW x AS SELECT CAST(1 AS DATETIME) AS a;',
        drift.DriftSqlType.dateTime,
        'CREATE VIEW x AS SELECT CAST(1 AS INT) AS a;',
        const DriftOptions.defaults(storeDateTimeValuesAsText: false),
      );
    });

    test('to datetime as text', () async {
      await expectView(
        "CREATE VIEW x AS SELECT CAST('x' AS DATETIME) AS a;",
        drift.DriftSqlType.dateTime,
        "CREATE VIEW x AS SELECT CAST('x' AS TEXT) AS a;",
        const DriftOptions.defaults(storeDateTimeValuesAsText: true),
      );
    });
  });
}
