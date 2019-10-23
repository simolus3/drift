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
}
