import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'utils.dart';

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
    expect(resultSet.scalarColumns.map((c) => c.sqlType.builtin),
        [DriftSqlType.string, DriftSqlType.bool]);
  });

  test('can read from builtin tables', () async {
    final state = TestBackend.inTest({
      'a|lib/main.drift': '''
testQuery: SELECT * FROM sqlite_schema;
      ''',
    });

    final file = await state.analyze('package:a/main.drift');
    state.expectNoErrors();

    final query = file.fileAnalysis!.resolvedQueries.values.single;
    expect(query, const TypeMatcher<SqlSelectQuery>());
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

    final isFromView = isExistingRowType(
      type: 'MyViewData',
      singleValue: isA<MatchingDriftTable>()
          .having((e) => e.table.schemaName, 'table.schemaName', 'my_view'),
    );

    expect(
      query.resultSet!.mappingToRowClass('', const DriftOptions.defaults()),
      isExistingRowType(
        named: {
          'foo': structedFromNested(isFromView),
          'bar': structedFromNested(isFromView),
        },
      ),
    );
  });

  test('infers nested result sets for custom result sets', () async {
    final state = TestBackend.inTest({
      'foo|lib/main.drift': r'''
query: SELECT 1 AS a, b.** FROM (SELECT 2 AS b, 3 AS c) AS b;
      ''',
    });

    final file = await state.analyze('package:foo/main.drift');
    state.expectNoErrors();

    final query = file.fileAnalysis!.resolvedQueries.values.single;

    expect(
      query.resultSet!.mappingToRowClass('Row', const DriftOptions.defaults()),
      isExistingRowType(
        type: 'Row',
        named: {
          'a': scalarColumn('a'),
          'b': structedFromNested(isExistingRowType(
            type: 'QueryNestedColumn0',
            named: {
              'b': scalarColumn('b'),
              'c': scalarColumn('c'),
            },
          )),
        },
      ),
    );
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
      expect(q1.resultSet!.scalarColumns.single.sqlType.builtin,
          DriftSqlType.dateTime);

      final q2 = queries[1];
      final q3 = queries[2];

      if (dateTimeAsText) {
        expect(q2.resultSet!.scalarColumns.single.sqlType.builtin,
            DriftSqlType.int);
        expect(q3.resultSet!.scalarColumns.single.sqlType.builtin,
            DriftSqlType.dateTime);
      } else {
        expect(q2.resultSet!.scalarColumns.single.sqlType.builtin,
            DriftSqlType.dateTime);
        expect(q3.resultSet!.scalarColumns.single.sqlType.builtin,
            DriftSqlType.string);
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
          .map((e) => e.innerResultSet.matchingTable!.table.schemaName),
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
          .having((e) => e.sqlType.builtin, 'sqlType', DriftSqlType.bool)
    ]);

    final args = query.variables;
    expect(args.map((e) => e.sqlType.builtin),
        [DriftSqlType.int, DriftSqlType.string]);
  });

  test('can cast to DATETIME and BOOLEAN', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': '''
a: SELECT CAST(1 AS BOOLEAN) AS a, CAST(2 AS DATETIME) as b;
''',
    });

    final state = await backend.analyze('package:a/a.drift');
    final query = state.fileAnalysis!.resolvedQueries.values.single;
    final resultSet = query.resultSet!;

    expect(resultSet.columns, [
      scalarColumn('a')
          .having((e) => e.sqlType.builtin, 'sqlType', DriftSqlType.bool),
      scalarColumn('b')
          .having((e) => e.sqlType.builtin, 'sqlType', DriftSqlType.dateTime),
    ]);
  });

  test('can cast to enum type', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'enum.dart';

a: SELECT
  1 AS c1,
  CAST(1 AS ENUM(MyEnum)) AS c2,
  CAST('foo' AS ENUMNAME(MyEnum)) AS c3;
''',
      'a|lib/enum.dart': '''
enum MyEnum {
  foo, bar
}
''',
    });

    final state = await backend.analyze('package:a/a.drift');
    backend.expectNoErrors();

    final query = state.fileAnalysis!.resolvedQueries.values.single;
    final resultSet = query.resultSet!;

    final isEnumConverter = isA<AppliedTypeConverter>().having(
        (e) => e.isDriftEnumTypeConverter, 'isDriftEnumTypeConverter', isTrue);

    expect(resultSet.columns, [
      scalarColumn('c1')
          .having((e) => e.typeConverter, 'typeConverter', isNull),
      scalarColumn('c2')
          .having((e) => e.typeConverter, 'typeConverter', isEnumConverter),
      scalarColumn('c3')
          .having((e) => e.typeConverter, 'typeConverter', isEnumConverter),
    ]);
  });
}
