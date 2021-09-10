import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'data.dart';

void main() {
  test('resolves index of variables', () {
    final engine = SqlEngine()..registerTable(demoTable);
    final context =
        engine.analyze('SELECT ? = :test FROM demo LIMIT ?4 OFFSET ?;');
    // indices:                1   2                      4        5

    final select = context.root as SelectStatement;
    final firstEquals = (select.columns[0] as ExpressionResultColumn).expression
        as BinaryExpression;
    final limit = select.limit as Limit;

    expect((firstEquals.left as Variable).resolvedIndex, 1);
    expect((firstEquals.right as Variable).resolvedIndex, 2);
    expect((limit.count as Variable).resolvedIndex, 4);
    expect((limit.offset as Variable).resolvedIndex, 5);
  });
}
