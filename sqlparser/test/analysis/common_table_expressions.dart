import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'data.dart';

void main() {
  test('resolves columns from CTEs', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final context = engine.analyze('''
      WITH
        cte (foo, bar) AS (SELECT * FROM demo)
      SELECT * FROM cte;
    ''');

    expect(context.errors, isEmpty);
    final select = context.root as SelectStatement;
    final types = context.types;

    expect(select.resolvedColumns.map((c) => c.name), ['foo', 'bar']);
    expect(
      select.resolvedColumns.map((c) => types.resolveColumn(c).type),
      [id.type, content.type],
    );
  });

  test('warns on column count mismatch', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final context = engine.analyze(''' 
      WITH
        cte (foo, bar, baz) AS (SELECT * FROM demo)
      SELECT 1;
    ''');

    expect(context.errors, hasLength(1));
    final error = context.errors.single;
    expect(error.type, AnalysisErrorType.cteColumnCountMismatch);
    expect(error.message, stringContainsInOrder(['3', '2']));
  });

  test('handles recursive CTEs', () {
    final engine = SqlEngine();

    final context = engine.analyze('''
      WITH RECURSIVE
        cnt(x) AS (
          SELECT 1
          UNION ALL
          SELECT x+1 FROM cnt
            LIMIT 1000000
        )
      SELECT x FROM cnt;
    ''');

    expect(context.errors, isEmpty);
    final select = context.root as SelectStatement;
    final column = context.typeOf(select.resolvedColumns.single);

    expect(column.type, const ResolvedType(type: BasicType.int));
  });
}
