//@dart=2.9
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/moor/create_table_reader.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_handler.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
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
  final mapper = TypeMapper();
  final engine = SqlEngine(EngineOptions(useMoorExtensions: true));
  final step = ParseMoorStep(Task(null, null, null),
      FoundFile(Uri.parse('file://foo'), FileType.moor), '');

  final parsedFoo = engine.parse(createFoo).rootNode as CreateTableStatement;
  final foo = await CreateTableReader(parsedFoo, step).extractTable(mapper);
  engine.registerTable(mapper.extractStructure(foo));

  final parsedBar = engine.parse(createBar).rootNode as CreateTableStatement;
  final bar = await CreateTableReader(parsedBar, step).extractTable(mapper);
  engine.registerTable(mapper.extractStructure(bar));

  SqlQuery parse(String sql) {
    final parsed = engine.analyze(sql);
    final fakeQuery = DeclaredDartQuery('query', sql);
    return QueryHandler(fakeQuery, parsed, mapper).handle();
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
    }, enableAnalyzer: false);

    final file = await state.analyze('package:foo/main.moor');
    final result = file.currentResult as ParsedMoorFile;
    state.close();

    expect(file.errors.errors, isEmpty);

    final query = result.resolvedQueries.single;
    final resultSet = (query as SqlSelectQuery).resultSet;

    expect(resultSet.columns.map((e) => e.name), ['id', 'from', 'to']);
    expect(resultSet.matchingTable, isNull);
    expect(resultSet.nestedResults.map((e) => e.name), ['from', 'to']);
    expect(resultSet.nestedResults.map((e) => e.table.sqlName),
        ['points', 'points']);
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
    }, enableAnalyzer: false);

    final file = await state.analyze('package:foo/main.moor');
    final result = file.currentResult as ParsedMoorFile;
    state.close();

    expect(file.errors.errors, isEmpty);

    final query = result.resolvedQueries.single;
    final resultSet = (query as SqlSelectQuery).resultSet;

    final nested = resultSet.nestedResults;
    expect(nested.map((e) => e.name),
        ['tableA1', 'tableA2', 'tableB1', 'tableB2']);
    expect(nested.map((e) => e.isNullable), [false, true, false, true]);
  });
}
