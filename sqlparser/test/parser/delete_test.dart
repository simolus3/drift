import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';

import 'utils.dart';

void main() {
  test('parses delete statements', () {
    testStatement(
      'DELETE FROM tbl WHERE id = 5',
      DeleteStatement(
        from: TableReference('tbl', null),
        where: BinaryExpression(
          Reference(columnName: 'id'),
          token(TokenType.equal),
          NumericLiteral(
            5,
            token(TokenType.numberLiteral),
          ),
        ),
      ),
    );
  });

  test('parses delete statements with RETURNING', () {
    testStatement(
      'DELETE FROM tbl RETURNING *;',
      DeleteStatement(
        from: TableReference('tbl', null),
        returning: Returning([StarResultColumn()]),
      ),
    );
  });
}
