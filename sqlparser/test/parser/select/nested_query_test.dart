import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('parses nested query statements', () {
    final stmt = SqlEngine(EngineOptions(useDriftExtensions: true))
        .parse('SELECT LIST(SELECT * FROM test) FROM test')
        .rootNode as SelectStatement;

    enforceHasSpan(stmt);
    return enforceEqual(
      stmt.columns[0],
      NestedQueryColumn(
        select: SelectStatement(
          columns: [StarResultColumn(null)],
          from: TableReference('test'),
        ),
      ),
    );
  });

  test('parses nested query statements with as', () {
    final stmt = SqlEngine(EngineOptions(useDriftExtensions: true))
        .parse('SELECT LIST(SELECT * FROM test) AS newname FROM test')
        .rootNode as SelectStatement;

    enforceHasSpan(stmt);
    return enforceEqual(
      stmt.columns[0],
      NestedQueryColumn(
        as: 'newname',
        select: SelectStatement(
          columns: [StarResultColumn(null)],
          from: TableReference('test'),
        ),
      ),
    );
  });
}
