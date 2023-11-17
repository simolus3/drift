import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

final Map<String, AstNode> testCases = {
  'UPDATE OR ROLLBACK tbl SET a = NULL, b = c WHERE d': UpdateStatement(
    or: FailureMode.rollback,
    table: TableReference('tbl'),
    set: [
      SingleColumnSetComponent(
        column: Reference(columnName: 'a'),
        expression: NullLiteral(),
      ),
      SingleColumnSetComponent(
        column: Reference(columnName: 'b'),
        expression: Reference(columnName: 'c'),
      )
    ],
    where: Reference(columnName: 'd'),
  ),
};

void main() {
  group('update statements', () {
    testAll(testCases);
  });

  test('parses updates with column-name-list and subquery', () {
    testStatement(
        '''
      UPDATE foo
      SET (a, b) = (SELECT b, a FROM bar AS b WHERE b.id=foo.id);
      ''',
        UpdateStatement(table: TableReference('foo'), set: [
          MultiColumnSetComponent(
              columns: [Reference(columnName: 'a'), Reference(columnName: 'b')],
              rowValue: SubQuery(
                  select: SelectStatement(
                      columns: [
                    ExpressionResultColumn(
                      expression: Reference(columnName: 'b'),
                    ),
                    ExpressionResultColumn(
                      expression: Reference(columnName: 'a'),
                    ),
                  ],
                      from: TableReference('bar', as: 'b'),
                      where: BinaryExpression(
                        Reference(entityName: 'b', columnName: 'id'),
                        token(TokenType.equal),
                        Reference(entityName: 'foo', columnName: 'id'),
                      ))))
        ]));
  });

  test('parses updates with column-name-list and scalar rowValues', () {
    testStatement(
        '''
      UPDATE foo
      SET (a, b) = (b, 3+4);
      ''',
        UpdateStatement(table: TableReference('foo'), set: [
          MultiColumnSetComponent(
              columns: [Reference(columnName: 'a'), Reference(columnName: 'b')],
              rowValue: Tuple(expressions: [
                Reference(columnName: "b"),
                BinaryExpression(NumericLiteral(3), token(TokenType.plus),
                    NumericLiteral(4)),
              ], usedAsRowValue: true))
        ]));
  });

  test('parses updates with FROM clause', () {
    testStatement(
      '''
      UPDATE inventory
        SET quantity = quantity - daily.amt
        FROM (SELECT sum(quantity) AS amt,
            itemId FROM sales GROUP BY 2) AS daily
        WHERE inventory.itemId = daily.itemId;
      ''',
      UpdateStatement(
        table: TableReference('inventory'),
        set: [
          SingleColumnSetComponent(
            column: Reference(columnName: 'quantity'),
            expression: BinaryExpression(
              Reference(columnName: 'quantity'),
              token(TokenType.minus),
              Reference(entityName: 'daily', columnName: 'amt'),
            ),
          ),
        ],
        from: SelectStatementAsSource(
          statement: SelectStatement(
            columns: [
              ExpressionResultColumn(
                expression: FunctionExpression(
                  name: 'sum',
                  parameters: ExprFunctionParameters(
                    parameters: [Reference(columnName: 'quantity')],
                  ),
                ),
                as: 'amt',
              ),
              ExpressionResultColumn(
                expression: Reference(columnName: 'itemId'),
              ),
            ],
            from: TableReference('sales'),
            groupBy: GroupBy(
              by: [NumericLiteral(2)],
            ),
          ),
          as: 'daily',
        ),
        where: BinaryExpression(
          Reference(entityName: 'inventory', columnName: 'itemId'),
          token(TokenType.equal),
          Reference(entityName: 'daily', columnName: 'itemId'),
        ),
      ),
    );
  });

  test('parses updates with RETURNING clause', () {
    testStatement(
      'UPDATE tbl SET foo = bar RETURNING *',
      UpdateStatement(
        table: TableReference('tbl'),
        set: [
          SingleColumnSetComponent(
            column: Reference(columnName: 'foo'),
            expression: Reference(columnName: 'bar'),
          ),
        ],
        returning: Returning([StarResultColumn()]),
      ),
    );
  });
}
