import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'existing_row_classes_test.dart';
import 'utils.dart';

Future<SqlQuery> _handle(String sql) async {
  return analyzeSingleQueryInDriftFile('''
CREATE TABLE foo (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR
);
CREATE TABLE bar (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  foo INTEGER NOT NULL REFERENCES foo(id)
);

a: $sql
''');
}

void main() {
  test('respects explicit type arguments', () async {
    final state = TestBackend.inTest({
      'foo|lib/main.drift': '''
bar(?1 AS TEXT, :foo AS BOOLEAN): SELECT ?, :foo;
      ''',
    });

    final file = await state.analyze('package:foo/main.drift');
    state.expectNoErrors();

    final query = file.fileAnalysis!.resolvedQueries.values.single;
    expect(query, const TypeMatcher<SqlSelectQuery>());

    final resultSet = (query as SqlSelectQuery).resultSet;
    expect(resultSet.matchingTable, isNull);
    expect(resultSet.scalarColumns.map((c) => c.name), ['?', ':foo']);
    expect(resultSet.scalarColumns.map((c) => c.sqlType),
        [DriftSqlType.string, DriftSqlType.bool]);
  });

  test('reads REQUIRED syntax', () async {
    final state = TestBackend.inTest({
      'foo|lib/main.drift': '''
bar(REQUIRED ?1 AS TEXT OR NULL, REQUIRED :foo AS BOOLEAN): SELECT ?, :foo;
      ''',
    });

    final file = await state.analyze('package:foo/main.drift');
    state.expectNoErrors();

    final query = file.fileAnalysis!.resolvedQueries.values.single;
    expect(
      query.variables,
      allOf(
        hasLength(2),
        everyElement(isA<FoundVariable>()
            .having((e) => e.isRequired, 'isRequired', isTrue)),
      ),
    );
  });

  group('detects whether multiple tables are referenced', () {
    test('when only selecting from one table', () async {
      final query = await _handle('SELECT * FROM foo;');
      expect(query.hasMultipleTables, isFalse);
    });

    test('when selecting from multiple tables', () async {
      final query =
          await _handle('SELECT * FROM bar JOIN foo ON bar.foo = foo.id;');

      expect(query.hasMultipleTables, isTrue);
    });

    test('when updating a single table', () async {
      final query = await _handle('INSERT INTO bar (foo) SELECT id FROM foo;');

      expect(query.hasMultipleTables, isTrue);
      expect((query as UpdatingQuery).updates, hasLength(1));
    });
  });

  test('infers result set for views', () async {
    final state = TestBackend.inTest({
      'foo|lib/main.drift': r'''
CREATE VIEW my_view AS SELECT 'foo', 2;

query: SELECT * FROM my_view;
      ''',
    });

    final file = await state.analyze('package:foo/main.drift');
    state.expectNoErrors();

    final query = file.fileAnalysis!.resolvedQueries.values.single;
    expect(
      query.resultSet!.matchingTable,
      isA<MatchingDriftTable>()
          .having(
            (e) => e.table,
            'table',
            isA<DriftView>()
                .having((e) => e.schemaName, 'schemaName', 'my_view'),
          )
          .having((e) => e.effectivelyNoAlias, 'effectivelyNoAlias', isTrue),
    );
  });

  test('infers nested result set for views', () async {
    final state = TestBackend.inTest({
      'foo|lib/main.drift': r'''
CREATE VIEW my_view AS SELECT 'foo', 2;

query: SELECT foo.**, bar.** FROM my_view foo, my_view bar;
      ''',
    });

    final file = await state.analyze('package:foo/main.drift');
    state.expectNoErrors();

    final query = file.fileAnalysis!.resolvedQueries.values.single;

    expect(query.resultSet!.nestedResults, hasLength(2));
    expect(
        query.resultSet!.nestedResults,
        everyElement(isA<NestedResultTable>()
            .having((e) => e.table.schemaName, 'table.schemName', 'my_view')));
  });

  for (final dateTimeAsText in [false, true]) {
    test('analyzing date times (stored as text: $dateTimeAsText)', () async {
      final state = TestBackend.inTest(
        {
          'foo|lib/foo.drift': r'''
CREATE TABLE foo (
  bar DATETIME NOT NULL
);

q1: SELECT bar FROM foo;
q2: SELECT unixepoch('now');
q3: SELECT datetime('now');
      ''',
        },
        options: DriftOptions.defaults(
          storeDateTimeValuesAsText: dateTimeAsText,
          sqliteAnalysisOptions: const SqliteAnalysisOptions(
            version: SqliteVersion.v3_38,
          ),
        ),
      );

      final file = await state.analyze('package:foo/foo.drift');
      state.expectNoErrors();

      final queries = file.fileAnalysis!.resolvedQueries.values.toList();
      expect(queries, hasLength(3));

      final q1 = queries[0];
      expect(q1.resultSet!.scalarColumns.single.sqlType, DriftSqlType.dateTime);

      final q2 = queries[1];
      final q3 = queries[2];

      if (dateTimeAsText) {
        expect(q2.resultSet!.scalarColumns.single.sqlType, DriftSqlType.int);
        expect(
            q3.resultSet!.scalarColumns.single.sqlType, DriftSqlType.dateTime);
      } else {
        expect(
            q2.resultSet!.scalarColumns.single.sqlType, DriftSqlType.dateTime);
        expect(q3.resultSet!.scalarColumns.single.sqlType, DriftSqlType.string);
      }
    });
  }

  test('resolves nested result sets', () async {
    final state = TestBackend.inTest({
      'foo|lib/main.drift': r'''
CREATE TABLE points (
  id INTEGER NOT NULL PRIMARY KEY,
  lat REAL NOT NULL,
  long REAL NOT NULL
);
CREATE TABLE routes (
  id INTEGER NOT NULL PRIMARY KEY,
  "from" INTEGER NOT NULL REFERENCES points (id),
  "to" INTEGER NOT NULL REFERENCES points (id)
);

allRoutes: SELECT routes.*, "from".**, "to".**
FROM routes
  INNER JOIN points "from" ON "from".id = routes.from
  INNER JOIN points "to" ON "to".id = routes."to";
      ''',
    });

    final file = await state.analyze('package:foo/main.drift');
    state.expectNoErrors();

    final query = file.fileAnalysis!.resolvedQueries.values.single;
    final resultSet = (query as SqlSelectQuery).resultSet;

    expect(resultSet.scalarColumns.map((e) => e.name), ['id', 'from', 'to']);
    expect(resultSet.matchingTable, isNull);
    expect(
      resultSet.nestedResults.cast<NestedResultTable>().map((e) => e.name),
      ['from', 'to'],
    );
    expect(
      resultSet.nestedResults
          .cast<NestedResultTable>()
          .map((e) => e.table.schemaName),
      ['points', 'points'],
    );
  });

  test('resolves nullability of aliases in nested result sets', () async {
    final state = TestBackend.inTest({
      'foo|lib/main.drift': r'''
CREATE TABLE tableA1 (id INTEGER);
CREATE TABLE tableB1 (id INTEGER);

query: SELECT
  tableA1.**,
  tableA2.**,
  tableB1.**,
  tableB2.**
FROM tableA1 -- not nullable

LEFT JOIN tableA1 AS tableA2 -- nullable
  ON FALSE

INNER JOIN tableB1 -- not nullable
  ON TRUE

LEFT JOIN tableB1 AS tableB2 -- nullable
   ON FALSE;
      ''',
    });

    final file = await state.analyze('package:foo/main.drift');
    state.expectNoErrors();

    final query = file.fileAnalysis!.resolvedQueries.values.single;
    final resultSet = (query as SqlSelectQuery).resultSet;

    final nested = resultSet.nestedResults;
    expect(
      nested.cast<NestedResultTable>().map((e) => e.name),
      ['tableA1', 'tableA2', 'tableB1', 'tableB2'],
    );
    expect(
      nested.cast<NestedResultTable>().map((e) => e.isNullable),
      [false, true, false, true],
    );
  });

  test('supports custom functions', () async {
    final withoutOptions =
        TestBackend.inTest({'a|lib/a.drift': 'a: SELECT my_function();'});
    var result = await withoutOptions.analyze('package:a/a.drift');
    expect(result.allErrors, [
      isDriftError('Function my_function could not be found')
          .withSpan('my_function'),
      isDriftError(startsWith('Expression has an unknown type'))
          .withSpan('my_function()'),
    ]);

    final withOptions =
        TestBackend.inTest({'a|lib/a.drift': 'a: SELECT my_function(?, ?);'},
            options: DriftOptions.defaults(
              sqliteAnalysisOptions: SqliteAnalysisOptions(knownFunctions: {
                'my_function':
                    KnownSqliteFunction.fromJson('boolean (int, text)')
              }),
            ));
    result = await withOptions.analyze('package:a/a.drift');

    withOptions.expectNoErrors();

    final query = result.fileAnalysis!.resolvedQueries.values.single;
    expect(query.resultSet!.columns, [
      isA<ScalarResultColumn>()
          .having((e) => e.sqlType, 'sqlType', DriftSqlType.bool)
    ]);

    final args = query.variables;
    expect(args.map((e) => e.sqlType), [DriftSqlType.int, DriftSqlType.string]);
  });
}
