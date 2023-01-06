import 'package:drift_dev/src/analysis/resolver/queries/explicit_alias_transformer.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';
import 'package:test/test.dart';

void main() {
  final engine =
      SqlEngine(EngineOptions(driftOptions: const DriftSqlOptions()));
  final result = engine.parse('CREATE TABLE a (id INTEGER);');
  engine.registerTable(const SchemaFromCreateTable()
      .read(result.rootNode as CreateTableStatement));

  void checkTransformation(String input, String output) {
    final node = engine.analyze(input).root;
    final transformer = ExplicitAliasTransformer();
    transformer.rewrite(node);

    expect(node.toSql(), output);
  }

  test('rewrites simple queries', () {
    checkTransformation('SELECT 1 + 2', 'SELECT 1 + 2 AS _c0');
  });

  test('does not rewrite simple references', () {
    checkTransformation('SELECT id FROM a', 'SELECT id FROM a');
  });

  test('rewrites references', () {
    checkTransformation('SELECT "1+2" FROM (SELECT 1+2)',
        'SELECT _c0 FROM (SELECT 1 + 2 AS _c0)');
  });

  test('does not rewrite subquery expressions', () {
    checkTransformation('SELECT (SELECT 1)', 'SELECT (SELECT 1) AS _c0');
  });

  test('rewrites compound select statements', () {
    checkTransformation("SELECT 1 + 2, 'foo' UNION ALL SELECT 3+ 4, 'bar'",
        "SELECT 1 + 2 AS _c0, 'foo' AS _c1 UNION ALL SELECT 3 + 4, 'bar'");
  });

  test('rewrites references for compount select statements', () {
    checkTransformation(
      '''
    SELECT "1 + 2", "'foo'" FROM
      (SELECT 1 + 2, 'foo' UNION ALL SELECT 3+ 4, 'bar')
    ''',
      'SELECT _c0, _c1 FROM '
          "(SELECT 1 + 2 AS _c0, 'foo' AS _c1 UNION ALL SELECT 3 + 4, 'bar')",
    );
  });

  test('rewrites references for compount select statements', () {
    checkTransformation(
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
    checkTransformation(
      '''
    WITH
     foo(x) AS (SELECT 2 * 3 UNION ALL SELECT 3)
    SELECT x FROM foo;
    ''',
      'WITH foo (x) AS (SELECT 2 * 3 UNION ALL SELECT 3) '
          'SELECT x FROM foo',
    );
  });

  test('rewrites RETURNING clauses', () {
    checkTransformation(
      'INSERT INTO a VALUES (1), (2) RETURNING id * 3',
      'INSERT INTO a VALUES (1), (2) RETURNING id * 3 AS _c0',
    );
  });
}
