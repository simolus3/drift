import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';

import 'utils.dart';

void main() {
  test('parses delete statements', () {
    final parsed = SqlEngine().parse('DELETE FROM table WHERE id = 5').rootNode;

    enforceEqual(
      parsed,
      DeleteStatement(
        from: TableReference('table', null),
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
}
