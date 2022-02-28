import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  void check(String sql, List<String> problems) {
    final engine = SqlEngine();
    final parseResult = engine.parse(sql);
    engine.registerTable(const SchemaFromCreateTable()
        .read(parseResult.rootNode as CreateTableStatement));

    final context = engine.analyzeParsed(parseResult);
    expect(
      context.errors,
      pairwiseCompare<String, AnalysisError>(
        problems,
        (span, err) => err.span?.text == span,
        'with span',
      ),
    );
  }

  test('not reported on a correct table', () {
    check(
      '''
        CREATE TABLE tbl (
          foo INTEGER PRIMARY KEY,
          bar TEXT
        );
      ''',
      [],
    );
  });

  test('multiple column constraints', () {
    check(
      '''
        CREATE TABLE tbl (
          foo INTEGER PRIMARY KEY,
          bar TEXT PRIMARY KEY,
        );
      ''',
      ['PRIMARY KEY'],
    );
  });

  test('with column and table constraints', () {
    check(
      '''
        CREATE TABLE tbl (
          foo INTEGER PRIMARY KEY,
          bar TEXT,
          PRIMARY KEY (foo, bar)
        );
      ''',
      ['PRIMARY KEY (foo, bar)'],
    );
  });

  test('multiple table constraints', () {
    check(
      '''
        CREATE TABLE tbl (
          foo INTEGER,
          bar TEXT,
          PRIMARY KEY (foo),
          PRIMARY KEY (bar)
        );
      ''',
      ['PRIMARY KEY (bar)'],
    );
  });
}
