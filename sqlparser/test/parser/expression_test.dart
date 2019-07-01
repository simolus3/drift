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
  '3 * 4 + 5 == COUNT(*)': BinaryExpression(
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
  '? * ?3 + ?2 == :test': BinaryExpression(
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
  'CASE x WHEN a THEN b WHEN c THEN d ELSE e END': CaseExpression(
    base: Reference(columnName: 'x'),
    whens: [
      WhenComponent(
        when: Reference(columnName: 'a'),
        then: Reference(columnName: 'b'),
      ),
      WhenComponent(
        when: Reference(columnName: 'c'),
        then: Reference(columnName: 'd'),
      ),
    ],
    elseExpr: Reference(columnName: 'e'),
  ),
  "x NOT LIKE '%A%\$' ESCAPE '\$'": StringComparisonExpression(
    not: true,
    left: Reference(columnName: 'x'),
    operator: token(TokenType.like),
    right: StringLiteral.from(token(TokenType.stringLiteral), '%A%\$'),
    escape: StringLiteral.from(token(TokenType.stringLiteral), '\$'),
  ),
  'NOT EXISTS (SELECT * FROM demo)': UnaryExpression(
    token(TokenType.not),
    ExistsExpression(
      select: SelectStatement(
        columns: [StarResultColumn(null)],
        from: [
          TableReference('demo', null),
        ],
      ),
    ),
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
}
