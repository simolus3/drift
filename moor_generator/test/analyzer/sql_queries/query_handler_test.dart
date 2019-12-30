import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/moor/create_table_reader.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_handler.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

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

void main() {
  final mapper = TypeMapper();
  final engine = SqlEngine(useMoorExtensions: true);
  final step = ParseMoorStep(
      Task(null, null, null), FoundFile(Uri.parse('foo'), FileType.moor), '');

  final parsedFoo = engine.parse(createFoo).rootNode as CreateTableStatement;
  final foo = CreateTableReader(parsedFoo, step).extractTable(mapper);
  engine.registerTable(mapper.extractStructure(foo));

  final parsedBar = engine.parse(createBar).rootNode as CreateTableStatement;
  final bar = CreateTableReader(parsedBar, step).extractTable(mapper);
  engine.registerTable(mapper.extractStructure(bar));

  SqlQuery parse(String sql) {
    final parsed = engine.analyze(sql);
    return QueryHandler('test', parsed, mapper).handle();
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
}
