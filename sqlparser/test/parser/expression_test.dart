import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import 'utils.dart';

final Map<String, Expression> _testCases = {
  '3 * 7 + 1 NOT BETWEEN 31 AND 74': BetweenExpression(
    not: true,
    check: BinaryExpression(
      BinaryExpression(
        NumericLiteral(3),
        token(TokenType.star),
        NumericLiteral(7),
      ),
      token(TokenType.plus),
      NumericLiteral(1),
    ),
    lower: NumericLiteral(31),
    upper: NumericLiteral(74),
  ),
  '3 * 4 + 5 == COUNT(*)': BinaryExpression(
    BinaryExpression(
      BinaryExpression(
        NumericLiteral(3),
        token(TokenType.star),
        NumericLiteral(4),
      ),
      token(TokenType.plus),
      NumericLiteral(5),
    ),
    token(TokenType.doubleEqual),
    FunctionExpression(name: 'COUNT', parameters: StarFunctionParameter()),
  ),
  '? * ?3 + ?2 == :test': BinaryExpression(
    BinaryExpression(
      BinaryExpression(
        NumberedVariable(null),
        token(TokenType.star),
        NumberedVariable(3),
      ),
      token(TokenType.plus),
      NumberedVariable(2),
    ),
    token(TokenType.doubleEqual),
    NamedVariable(ColonVariableToken(fakeSpan(':test'), 'test')),
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
    right: StringLiteral('%A%\$'),
    escape: StringLiteral('\$'),
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
      columns: [ExpressionResultColumn(expression: Reference(columnName: 'x'))],
    ),
  ),
  "'hello' || 'world' COLLATE NOCASE": BinaryExpression(
    StringLiteral('hello'),
    token(TokenType.doublePipe),
    CollateExpression(
      operator: token(TokenType.collate),
      inner: StringLiteral('world'),
      collateFunction: token(TokenType.identifier),
    ),
  ),
  'x in ?': InExpression(
    left: Reference(columnName: 'x'),
    inside: NumberedVariable(null),
  ),
  'x IN (SELECT col FROM tbl)': InExpression(
    left: Reference(columnName: 'x'),
    inside: SubQuery(
      select: SelectStatement(
        columns: [
          ExpressionResultColumn(expression: Reference(columnName: 'col')),
        ],
        from: TableReference('tbl'),
      ),
    ),
  ),
  'x IN (1, 2, (SELECT 3))': InExpression(
    left: Reference(columnName: 'x'),
    inside: Tuple(
      expressions: [
        NumericLiteral(1.0),
        NumericLiteral(2.0),
        SubQuery(
          select: SelectStatement(
            columns: [ExpressionResultColumn(expression: NumericLiteral(3.0))],
          ),
        ),
      ],
    ),
  ),
  'x IN json_each(bar)': InExpression(
    left: Reference(columnName: 'x'),
    inside: TableValuedFunction(
      'json_each',
      ExprFunctionParameters(parameters: [Reference(columnName: 'bar')]),
    ),
  ),
  'x NOT IN "table"': InExpression(
    not: true,
    left: Reference(columnName: 'x'),
    inside: TableReference('table'),
  ),
  'CAST(3 + 4 AS TEXT)': CastExpression(
    BinaryExpression(
      NumericLiteral(3.0),
      token(TokenType.plus),
      NumericLiteral(4.0),
    ),
    'TEXT',
  ),
  'CAST(1 AS)': CastExpression(NumericLiteral(1.0), ''),
  'foo ISNULL': IsNullExpression(Reference(columnName: 'foo')),
  'foo NOTNULL': IsNullExpression(Reference(columnName: 'foo'), true),
  'CURRENT_TIME': TimeConstantLiteral(TimeConstantKind.currentTime),
  'CURRENT_TIMESTAMP': TimeConstantLiteral(TimeConstantKind.currentTimestamp),
  'CURRENT_DATE': TimeConstantLiteral(TimeConstantKind.currentDate),
  '(1, 2, 3) > (?, ?, ?)': BinaryExpression(
    Tuple(expressions: [for (var i = 1; i <= 3; i++) NumericLiteral(i)]),
    token(TokenType.more),
    Tuple(
      expressions: [
        NumberedVariable(null),
        NumberedVariable(null),
        NumberedVariable(null),
      ],
    ),
  ),
  'RAISE(IGNORE)': RaiseExpression(RaiseKind.ignore),
  "RAISE(ROLLBACK, 'Not allowed')": RaiseExpression(
    RaiseKind.rollback,
    'Not allowed',
  ),
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
        final result = SqlEngine().parse(ParserEntrypoint.expression, sql);
        final expression = result.rootNode;

        expect(result.errors, isEmpty);
        enforceHasSpan(expression);
        enforceEqual(expression, expected);
      });
    });
  });

  group('named variables', () {
    test('support all kinds when not in drift mode', () {
      for (final prefix in [':', '@', r'$']) {
        final result = SqlEngine().parse(
          ParserEntrypoint.statement,
          'SELECT ${prefix}name;',
        );
        final value =
            ((result.rootNode as SelectStatement).columns.single
                        as ExpressionResultColumn)
                    .expression
                as NamedVariable;

        expect(value.name, 'name');
        expect(value.fullName, '${prefix}name');
      }
    });

    test('does not parse at and dollar signs as variables in drift mode', () {
      final engine = SqlEngine(EngineOptions(driftOptions: DriftSqlOptions()));
      expect(
        engine.parse(ParserEntrypoint.statement, 'SELECT @name').rootNode,
        isA<InvalidStatement>(),
      );

      final result = engine.parse(ParserEntrypoint.statement, r'SELECT $name;');
      final value =
          ((result.rootNode as SelectStatement).columns.single
                  as ExpressionResultColumn)
              .expression;
      expect(value, isA<DartExpressionPlaceholder>());
    });
  });

  test('schema in function names', () {
    final engine = SqlEngine();
    expect(
      engine.parse(ParserEntrypoint.statement, 'SELECT foo.bar(1)').errors,
      [
        isParsingError(
          message: 'Invalid schema name for function call',
          span: 'foo',
        ),
      ],
    );

    final optInEngine = SqlEngine(
      EngineOptions(supportSchemaInFunctionNames: true),
    );

    final parsed = optInEngine.parse(
      ParserEntrypoint.statement,
      'SELECT foo.bar(1)',
    );
    enforceHasSpan(parsed.rootNode);
    enforceEqual(
      parsed.rootNode,
      SelectStatement(
        columns: [
          ExpressionResultColumn(
            expression: FunctionExpression(
              name: 'bar',
              schemaName: 'foo',
              parameters: ExprFunctionParameters(
                parameters: [NumericLiteral(1)],
              ),
            ),
          ),
        ],
      ),
    );
  });

  test('postgres casts', () {
    final engine = SqlEngine(EngineOptions(supportPostgresCasts: true));
    final parsed = engine
        .parse(ParserEntrypoint.expression, 'foo::text')
        .rootNode;
    enforceHasSpan(parsed);
    enforceEqual(parsed, CastExpression(Reference(columnName: 'foo'), 'text'));
  });
}
