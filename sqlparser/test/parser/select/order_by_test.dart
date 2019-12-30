import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';

import '../utils.dart';

void main() {
  test('parses order by clauses', () {
    final parsed = SqlEngine()
        .parse('SELECT * FROM tbl ORDER BY -a, b DESC')
        .rootNode as SelectStatement;

    enforceHasSpan(parsed);
    enforceEqual(
      parsed.orderBy,
      OrderBy(
        terms: [
          OrderingTerm(
            expression: UnaryExpression(
              token(TokenType.minus),
              Reference(columnName: 'a'),
            ),
          ),
          OrderingTerm(
            orderingMode: OrderingMode.descending,
            expression: Reference(columnName: 'b'),
          ),
        ],
      ),
    );
  });
}
