import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';

import '../utils.dart';

void main() {
  test('parses group by statements', () {
    final stmt = SqlEngine()
        .parse("SELECT * FROM test GROUP BY country HAVING country LIKE '%G%'")
        .rootNode as SelectStatement;

    enforceHasSpan(stmt);
    return enforceEqual(
      stmt.groupBy,
      GroupBy(
        by: [Reference(columnName: 'country')],
        having: StringComparisonExpression(
          left: Reference(columnName: 'country'),
          operator: token(TokenType.like),
          right: StringLiteral.from(token(TokenType.stringLiteral), '%G%'),
        ),
      ),
    );
  });
}
