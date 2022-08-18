import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
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
      parameters: StarFunctionParameter(),
    ),
  ),
  '? * ?3 + ?2 == :test': BinaryExpression(
    BinaryExpression(
      BinaryExpression(
        NumberedVariable(QuestionMarkVariableToken(fakeSpan('?'), null)),
        token(TokenType.star),
        NumberedVariable(QuestionMarkVariableToken(fakeSpan('?3'), 3)),
      ),
      token(TokenType.plus),
      NumberedVariable(QuestionMarkVariableToken(fakeSpan('?2'), 2)),
    ),
    token(TokenType.doubleEqual),
    ColonNamedVariable(ColonVariableToken(fakeSpan(':test'), ':test')),
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
  'CASE WHEN a THEN '
      'CASE WHEN b THEN c ELSE d END '
      'ELSE '
      'CASE WHEN e THEN f ELSE g END '
      'END': CaseExpression(
    whens: [
      WhenComponent(
        when: Reference(columnName: 'a'),
        then: CaseExpression(
          whens: [
            WhenComponent(
              when: Reference(columnName: 'b'),
              then: Reference(columnName: 'c'),
            ),
          ],
          elseExpr: Reference(columnName: 'd'),
        ),
      ),
    ],
    elseExpr: CaseExpression(
      whens: [
        WhenComponent(
          when: Reference(columnName: 'e'),
          then: Reference(columnName: 'f'),
        ),
      ],
      elseExpr: Reference(columnName: 'g'),
    ),
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
        from: TableReference('demo'),
      ),
    ),
  ),
  '(SELECT x)': SubQuery(
    select: SelectStatement(
      columns: [
        ExpressionResultColumn(
          expression: Reference(columnName: 'x'),
        ),
      ],
    ),
  ),
  "'hello' || 'world' COLLATE NOCASE": BinaryExpression(
    StringLiteral.from(token(TokenType.stringLiteral), 'hello'),
    token(TokenType.doublePipe),
    CollateExpression(
      operator: token(TokenType.collate),
      inner: StringLiteral.from(token(TokenType.stringLiteral), 'world'),
      collateFunction: token(TokenType.identifier),
    ),
  ),
  'x in ?': InExpression(
    left: Reference(columnName: 'x'),
    inside: NumberedVariable(QuestionMarkVariableToken(fakeSpan('?'), null)),
  ),
  'x IN (SELECT col FROM tbl)': InExpression(
    left: Reference(columnName: 'x'),
    inside: SubQuery(
      select: SelectStatement(
        columns: [
          ExpressionResultColumn(
            expression: Reference(columnName: 'col'),
          )
        ],
        from: TableReference('tbl'),
      ),
    ),
  ),
  'x IN (1, 2, (SELECT 3))': InExpression(
    left: Reference(columnName: 'x'),
    inside: Tuple(
      expressions: [
        NumericLiteral(1.0, token(TokenType.numberLiteral)),
        NumericLiteral(2.0, token(TokenType.numberLiteral)),
        SubQuery(
          select: SelectStatement(columns: [
            ExpressionResultColumn(
              expression: NumericLiteral(3.0, token(TokenType.numberLiteral)),
            ),
          ]),
        ),
      ],
    ),
  ),
  'CAST(3 + 4 AS TEXT)': CastExpression(
    BinaryExpression(
      NumericLiteral(3.0, token(TokenType.numberLiteral)),
      token(TokenType.plus),
      NumericLiteral(4.0, token(TokenType.numberLiteral)),
    ),
    'TEXT',
  ),
  'foo ISNULL': IsNullExpression(Reference(columnName: 'foo')),
  'foo NOTNULL': IsNullExpression(Reference(columnName: 'foo'), true),
  'CURRENT_TIME': TimeConstantLiteral(
      TimeConstantKind.currentTime, token(TokenType.currentTime)),
  'CURRENT_TIMESTAMP': TimeConstantLiteral(
      TimeConstantKind.currentTimestamp, token(TokenType.currentTimestamp)),
  'CURRENT_DATE': TimeConstantLiteral(
      TimeConstantKind.currentDate, token(TokenType.currentDate)),
  '(1, 2, 3) > (?, ?, ?)': BinaryExpression(
    Tuple(expressions: [
      for (var i = 1; i <= 3; i++)
        NumericLiteral(i, token(TokenType.numberLiteral)),
    ]),
    token(TokenType.more),
    Tuple(expressions: [
      NumberedVariable(QuestionMarkVariableToken(fakeSpan('?'), null)),
      NumberedVariable(QuestionMarkVariableToken(fakeSpan('?'), null)),
      NumberedVariable(QuestionMarkVariableToken(fakeSpan('?'), null)),
    ]),
  ),
  'RAISE(IGNORE)': RaiseExpression(RaiseKind.ignore),
  "RAISE(ROLLBACK, 'Not allowed')":
      RaiseExpression(RaiseKind.rollback, 'Not allowed'),
  'foo': Reference(columnName: 'foo'),
  'foo.bar': Reference(entityName: 'foo', columnName: 'bar'),
  'foo.bar.baz': Reference(
    schemaName: 'foo',
    entityName: 'bar',
    columnName: 'baz',
  ),
  'foo IS DISTINCT FROM bar': IsExpression(
    false,
    Reference(columnName: 'foo'),
    Reference(columnName: 'bar'),
    distinctFromSyntax: true,
  ),
  'foo IS NOT DISTINCT FROM bar': IsExpression(
    true,
    Reference(columnName: 'foo'),
    Reference(columnName: 'bar'),
    distinctFromSyntax: true,
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

        enforceHasSpan(expression);
        enforceEqual(expression, expected);
      });
    });
  });
}
