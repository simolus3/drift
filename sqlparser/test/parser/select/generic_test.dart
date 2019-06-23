import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('parses select statements', () {
    final scanner = Scanner(
        'SELECT table.*, *, 1 as name WHERE 1 ORDER BY name LIMIT 3 OFFSET 5');
    final tokens = scanner.scanTokens();
    final parser = Parser(tokens);

    final stmt = parser.select();
    enforceEqual(
      stmt,
      SelectStatement(
        columns: [
          StarResultColumn('table'),
          StarResultColumn(null),
          ExpressionResultColumn(
            expression: NumericLiteral(1, token(TokenType.numberLiteral)),
            as: 'name',
          ),
        ],
        where: NumericLiteral(1, token(TokenType.numberLiteral)),
        orderBy: OrderBy(terms: [
          OrderingTerm(expression: Reference(columnName: 'name')),
        ]),
        limit: Limit(
          count: NumericLiteral(3, token(TokenType.numberLiteral)),
          offsetSeparator: token(TokenType.offset),
          offset: NumericLiteral(5, token(TokenType.numberLiteral)),
        ),
      ),
    );
  });
}
