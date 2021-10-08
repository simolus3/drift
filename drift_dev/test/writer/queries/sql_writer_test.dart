//@dart=2.9
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/writer/queries/sql_writer.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  void check(String sql, String expectedDart) {
    final engine = SqlEngine();
    final context = engine.analyze(sql);
    final query = SqlSelectQuery(
        'name', context, [], [], InferredResultSet(null, []), null);

    final result = SqlWriter(query).write();

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
}
