import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import 'utils.dart';

final Map<String, Expression> _testCases = {
  '3 * 7 + 1 NOT BETWEEN 31 AND 74': BetweenExpression(
    not: true,
    check: BinaryExpression(
      BinaryExpression(
        NumericLiteral(3, token(TokenType.numberLiteral)),
        token(TokenType.star),
        NumericLiteral(7, token(TokenType.numberLiteral)),
      ),
      token(TokenType.plus),
      NumericLiteral(1, token(TokenType.numberLiteral)),
    ),
    lower: NumericLiteral(31, token(TokenType.numberLiteral)),
    upper: NumericLiteral(74, token(TokenType.numberLiteral)),
  ),
};

void main() {
  group('expresssion test cases', () {
    _testCases.forEach((sql, expected) {
      test(sql, () {
        final scanner = Scanner(sql);
        final tokens = scanner.scanTokens();
        final parser = Parser(tokens);
        final expression = parser.expression();
        enforceEqual(expression, expected);
      });
    });
  });

  test('parses simple expressions', () {
    final scanner = Scanner('3 * 4 + 5 == COUNT(*)');
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
        FunctionExpression(
          name: 'COUNT',
          parameters: const StarFunctionParameter(),
        ),
      ),
    );
  });

  test('variables', () {
    final scanner = Scanner('? * ?3 + ?2 == :test');
    final tokens = scanner.scanTokens();
    final parser = Parser(tokens);

    final expression = parser.expression();

    enforceEqual(
      expression,
      BinaryExpression(
        BinaryExpression(
          BinaryExpression(
            NumberedVariable(token(TokenType.questionMark), null),
            token(TokenType.star),
            NumberedVariable(token(TokenType.questionMark), 3),
          ),
          token(TokenType.plus),
          NumberedVariable(token(TokenType.questionMark), 2),
        ),
        token(TokenType.doubleEqual),
        ColonNamedVariable(':test'),
      ),
    );
  });
}
