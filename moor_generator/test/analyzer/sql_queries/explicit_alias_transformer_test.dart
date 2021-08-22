import 'package:moor_generator/src/analyzer/sql_queries/explicit_alias_transformer.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';
import 'package:test/test.dart';

void main() {
  final engine = SqlEngine(EngineOptions(useMoorExtensions: true));
  final result = engine.parse('CREATE TABLE a (id INTEGER);');
  engine.registerTable(const SchemaFromCreateTable()
      .read(result.rootNode as CreateTableStatement));

  void _test(String input, String output) {
    final node = engine.analyze(input).root;
    final transformer = ExplicitAliasTransformer();
    transformer.rewrite(node);

    expect(node.toSql(), output);
  }

  test('rewrites simple queries', () {
    _test('SELECT 1 + 2', 'SELECT 1 + 2 AS _c0');
  });

  test('does not rewrite simple references', () {
    _test('SELECT id FROM a', 'SELECT id FROM a');
  });

  test('rewrites references', () {
    _test('SELECT "1+2" FROM (SELECT 1+2)',
        'SELECT _c0 FROM (SELECT 1 + 2 AS _c0)');
  });

  test('does not rewrite subquery expressions', () {
    _test('SELECT (SELECT 1)', 'SELECT (SELECT 1) AS _c0');
  });

  test('rewrites compound select statements', () {
    _test("SELECT 1 + 2, 'foo' UNION ALL SELECT 3+ 4, 'bar'",
        "SELECT 1 + 2 AS _c0, 'foo' AS _c1 UNION ALL SELECT 3 + 4, 'bar'");
  });

  test('rewrites references for compount select statements', () {
    _test(
      '''
    SELECT "1 + 2", "'foo'" FROM
      (SELECT 1 + 2, 'foo' UNION ALL SELECT 3+ 4, 'bar')
    ''',
      'SELECT _c0, _c1 FROM '
          "(SELECT 1 + 2 AS _c0, 'foo' AS _c1 UNION ALL SELECT 3 + 4, 'bar')",
    );
  });

  test('rewrites references for compount select statements', () {
    _test(
      '''
    WITH
     foo AS (SELECT 2 * 3 UNION ALL SELECT 3)
    SELECT "2 * 3" FROM foo;
    ''',
      'WITH foo AS (SELECT 2 * 3 AS _c0 UNION ALL SELECT 3) '
          'SELECT _c0 FROM foo',
    );
  });

  test('does not rewrite compound select statements with explicit names', () {
    _test(
      '''
    WITH
     foo(x) AS (SELECT 2 * 3 UNION ALL SELECT 3)
    SELECT x FROM foo;
    ''',
      'WITH foo(x) AS (SELECT 2 * 3 UNION ALL SELECT 3) '
          'SELECT x FROM foo',
    );
  });

  test('rewrites RETURNING clauses', () {
    _test(
      'INSERT INTO a VALUES (1), (2) RETURNING id * 3',
      'INSERT INTO a VALUES (1), (2) RETURNING id * 3 AS _c0',
    );
  });
}
