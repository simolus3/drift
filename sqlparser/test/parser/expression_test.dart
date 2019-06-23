import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('parses simple expressions', () {
    final scanner = Scanner('3 * 4 + 5 == 17');
    final tokens = scanner.scanTokens();
    final parser = Parser(tokens);

    final expression = parser.expression();
    enforceEqual(
      expression,
      BinaryExpression(
        BinaryExpression(
          BinaryExpression(
            NumericLiteral(3, token(TokenType.numberLiteral)),
            token(TokenType.star),
            NumericLiteral(4, token(TokenType.numberLiteral)),
          ),
          token(TokenType.plus),
          NumericLiteral(5, token(TokenType.numberLiteral)),
        ),
        token(TokenType.doubleEqual),
        NumericLiteral(17, token(TokenType.numberLiteral)),
      ),
    );
  });
}
