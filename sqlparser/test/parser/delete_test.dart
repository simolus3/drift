import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('parses delete statements', () {
    testStatement(
      'DELETE FROM tbl WHERE id = 5',
      DeleteStatement(
        from: TableReference('tbl'),
        where: BinaryExpression(
          Reference(columnName: 'id'),
          token(TokenType.equal),
          NumericLiteral(
            5,
          ),
        ),
      ),
    );
  });

  test('parses delete statements with RETURNING', () {
    testStatement(
      'DELETE FROM tbl RETURNING *;',
      DeleteStatement(
        from: TableReference('tbl'),
        returning: Returning([StarResultColumn()]),
      ),
    );
  });
}
