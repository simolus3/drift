import 'package:drift/drift.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/queries/sql_writer.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  void check(String sql, String expectedDart,
      {DriftOptions options = const DriftOptions.defaults()}) {
    final engine = SqlEngine();
    final context = engine.analyze(sql);
    final query = SqlSelectQuery('name', context, context.root, [], [],
        InferredResultSet(null, []), null, null);

    final result = SqlWriter(options, query: query).write();

    expect(result, expectedDart);
  }

  test('removes unnecessary whitespace', () {
    check(r'SELECT 1    + 3 AS r', r"'SELECT 1 + 3 AS r'");
  });

  test('removes comments', () {
    check(r'SELECT /*comment*/ 1', r"'SELECT 1'");
  });

  test('escapes Dart characters in SQL', () {
    check(r"SELECT '$hey';", r"'SELECT \'\$hey\''");
  });

  test('escapes postgres keywords', () {
    check('SELECT * FROM user', "'SELECT * FROM user'");
    check('SELECT * FROM user', "'SELECT * FROM \"user\"'",
        options: DriftOptions.defaults(
            dialect: DialectOptions(SqlDialect.postgres, null)));
  });
}
