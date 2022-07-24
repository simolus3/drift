import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/drift/create_table_reader.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/analyzer/runner/steps.dart';
import 'package:drift_dev/src/analyzer/sql_queries/query_handler.dart';
import 'package:drift_dev/src/analyzer/sql_queries/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

const createFoo = '''
CREATE TABLE foo (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR
);
''';

const createBar = '''
CREATE TABLE bar (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  foo INTEGER NOT NULL REFERENCES foo(id)
);
''';

Future<void> main() async {
  final mapper = TypeMapper(options: const DriftOptions.defaults());
  final engine = SqlEngine(EngineOptions(useDriftExtensions: true));
  final state = TestState.withContent({'a|lib/foo.drift': 'foo'});
  tearDownAll(state.close);
  final task = await state.runTask('package:a/foo.drift');

  final step = ParseMoorStep(
      task, FoundFile(Uri.parse('file://foo'), FileType.drift), '');

  final parsedFoo = engine.parse(createFoo).rootNode as CreateTableStatement;
  final foo = await CreateTableReader(parsedFoo, step, await task.helper)
      .extractTable(mapper);
  engine.registerTable(mapper.extractStructure(foo!));

  final parsedBar = engine.parse(createBar).rootNode as CreateTableStatement;
  final bar = await CreateTableReader(parsedBar, step, await task.helper)
      .extractTable(mapper);
  engine.registerTable(mapper.extractStructure(bar!));

  SqlQuery parse(String sql) {
    final parsed = engine.analyze(sql);
    final fakeQuery = DeclaredDartQuery('query', sql);
    return QueryHandler(parsed, mapper).handle(fakeQuery);
  }

  group('detects whether multiple tables are referenced', () {
    test('when only selecting from one table', () {
      expect(parse('SELECT * FROM foo').hasMultipleTables, isFalse);
    });

    test('when selecting from multiple tables', () {
      expect(
        parse('SELECT * FROM bar JOIN foo ON bar.foo = foo.id')
            .hasMultipleTables,
        isTrue,
      );
    });

    test('when updating a single table', () {
      final query = parse('INSERT INTO bar (foo) SELECT id FROM foo');

      expect(query.hasMultipleTables, isTrue);
      expect((query as UpdatingQuery).updates, hasLength(1));
    });
  });

  test('throws when variable indexes are skipped', () {
    expect(() => parse('SELECT ?2'), throwsStateError);
    expect(() => parse('SELECT ?1 = ?3'), throwsStateError);
    expect(() => parse('SELECT ?1 = ?3 OR ?2'), returnsNormally);
  });

  test('resolves nested result sets', () async {
    final state = TestState.withContent({
      'foo|lib/main.moor': r'''
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

    final file = await state.analyze('package:foo/main.moor');
    final result = file.currentResult as ParsedDriftFile;
    state.close();

    expect(file.errors.errors, isEmpty);

    final query = result.resolvedQueries!.single;
    final resultSet = (query as SqlSelectQuery).resultSet;

    expect(resultSet.columns.map((e) => e.name), ['id', 'from', 'to']);
    expect(resultSet.matchingTable, isNull);
    expect(
      resultSet.nestedResults.cast<NestedResultTable>().map((e) => e.name),
      ['from', 'to'],
    );
    expect(
      resultSet.nestedResults
          .cast<NestedResultTable>()
          .map((e) => e.table.displayName),
      ['points', 'points'],
    );
  });

  test('resolves nullability of aliases in nested result sets', () async {
    final state = TestState.withContent({
      'foo|lib/main.moor': r'''
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

    final file = await state.analyze('package:foo/main.moor');
    final result = file.currentResult as ParsedDriftFile;
    state.close();

    expect(file.errors.errors, isEmpty);

    final query = result.resolvedQueries!.single;
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

  test('infers result set for views', () async {
    final state = TestState.withContent({
      'foo|lib/main.moor': r'''
CREATE VIEW my_view AS SELECT 'foo', 2;

query: SELECT * FROM my_view;
      ''',
    });

    final file = await state.analyze('package:foo/main.moor');
    expect(file.errors.errors, isEmpty);

    final result = file.currentResult as ParsedDriftFile;

    final query = result.resolvedQueries!.single;
    expect(
        query.resultSet!.matchingTable,
        isA<MatchingMoorTable>()
            .having((e) => e.table, 'table',
                isA<MoorView>().having((e) => e.name, 'name', 'my_view'))
            .having((e) => e.effectivelyNoAlias, 'effectivelyNoAlias', isTrue));
  });

  test('infers nested result set for views', () async {
    final state = TestState.withContent({
      'foo|lib/main.moor': r'''
CREATE VIEW my_view AS SELECT 'foo', 2;

query: SELECT foo.**, bar.** FROM my_view foo, my_view bar;
      ''',
    });

    final file = await state.analyze('package:foo/main.moor');
    expect(file.errors.errors, isEmpty);

    final result = file.currentResult as ParsedDriftFile;
    final query = result.resolvedQueries!.single;

    expect(query.resultSet!.nestedResults, hasLength(2));
    expect(
        query.resultSet!.nestedResults,
        everyElement(isA<NestedResultTable>().having(
            (e) => e.table.displayName, 'table.displayName', 'my_view')));
  });

  for (final dateTimeAsText in [false, true]) {
    test('analyzing date times (stored as text: $dateTimeAsText)', () async {
      final state = TestState.withContent(
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
      addTearDown(state.close);

      final file = await state.analyze('package:foo/foo.drift');
      expect(file.errors.errors, isEmpty);

      final result = file.currentResult as ParsedDriftFile;
      expect(result.resolvedQueries, hasLength(3));

      final q1 = result.resolvedQueries![0];
      expect(q1.resultSet!.columns.single.type, DriftSqlType.dateTime);

      final q2 = result.resolvedQueries![1];
      final q3 = result.resolvedQueries![2];

      if (dateTimeAsText) {
        expect(q2.resultSet!.columns.single.type, DriftSqlType.int);
        expect(q3.resultSet!.columns.single.type, DriftSqlType.dateTime);
      } else {
        expect(q2.resultSet!.columns.single.type, DriftSqlType.dateTime);
        expect(q3.resultSet!.columns.single.type, DriftSqlType.string);
      }
    });
  }
}
