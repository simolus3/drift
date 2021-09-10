import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:test/test.dart';

import 'utils.dart';

final Map<String, AstNode> testCases = {
  'UPDATE OR ROLLBACK tbl SET a = NULL, b = c WHERE d': UpdateStatement(
    or: FailureMode.rollback,
    table: TableReference('tbl'),
    set: [
      SetComponent(
        column: Reference(columnName: 'a'),
        expression: NullLiteral(
          token(TokenType.$null),
        ),
      ),
      SetComponent(
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
          SetComponent(
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
              by: [NumericLiteral(2, token(TokenType.numberLiteral))],
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
          SetComponent(
            column: Reference(columnName: 'foo'),
            expression: Reference(columnName: 'bar'),
          ),
        ],
        returning: Returning([StarResultColumn()]),
      ),
    );
  });
}
