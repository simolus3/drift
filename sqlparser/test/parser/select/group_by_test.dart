import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';

import '../utils.dart';

void main() {
  test('parses group by statements', () {
    final stmt = SqlEngine().parse(
            "SELECT * FROM test GROUP BY country HAVING country LIKE '%G%'")
        as SelectStatement;

    return enforceEqual(
      stmt.groupBy,
      GroupBy(
        by: [Reference(columnName: 'country')],
        having: BinaryExpression(
          Reference(columnName: 'country'),
          token(TokenType.like),
          StringLiteral.from(token(TokenType.stringLiteral), '%G%'),
        ),
      ),
    );
  });
}
