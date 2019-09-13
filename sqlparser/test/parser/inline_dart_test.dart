import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('parses limit components', () {
    testStatement(
      r'SELECT * FROM tbl LIMIT $limit',
      SelectStatement(
        columns: [StarResultColumn(null)],
        from: [TableReference('tbl', null)],
        limit: InlineDartLimit(name: 'limit'),
      ),
      moorMode: true,
    );
  });

  test('parses limit counts as expressions', () {
    testStatement(
      r'SELECT * FROM tbl LIMIT $amount OFFSET 3',
      SelectStatement(
        columns: [StarResultColumn(null)],
        from: [TableReference('tbl', null)],
        limit: Limit(
          count: InlineDartExpression(name: 'amount'),
          offsetSeparator: token(TokenType.offset),
          offset: NumericLiteral(3, token(TokenType.numberLiteral)),
        ),
      ),
      moorMode: true,
    );
  });
}
