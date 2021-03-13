import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('parses WITH clauses', () {
    testStatement(
      ''' 
      WITH RECURSIVE
        cnt(x) AS (
          SELECT 1
          UNION ALL
          SELECT x+1 FROM cnt
          LIMIT 1000000
        )
        SELECT x FROM cnt;
      ''',
      SelectStatement(
        withClause: WithClause(
          recursive: true,
          ctes: [
            CommonTableExpression(
              cteTableName: 'cnt',
              columnNames: ['x'],
              as: CompoundSelectStatement(
                base: SelectStatement(
                  columns: [
                    ExpressionResultColumn(
                      expression: NumericLiteral(
                        1,
                        token(TokenType.numberLiteral),
                      ),
                    ),
                  ],
                ),
                additional: [
                  CompoundSelectPart(
                    mode: CompoundSelectMode.unionAll,
                    select: SelectStatement(
                      columns: [
                        ExpressionResultColumn(
                          expression: BinaryExpression(
                            Reference(columnName: 'x'),
                            token(TokenType.plus),
                            NumericLiteral(1, token(TokenType.numberLiteral)),
                          ),
                        ),
                      ],
                      from: TableReference('cnt'),
                      limit: Limit(
                        count: NumericLiteral(
                          1000000,
                          token(TokenType.numberLiteral),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        columns: [
          ExpressionResultColumn(expression: Reference(columnName: 'x')),
        ],
        from: TableReference('cnt'),
      ),
    );
  });

  test('parses MATERIALIZED / NOT MATERIALIZED clauses', () {
    testStatement(
      ''' 
      WITH
        foo(x) AS MATERIALIZED (SELECT *),
        bar(x) AS NOT MATERIALIZED (SELECT *)
        SELECT *;
      ''',
      SelectStatement(
        withClause: WithClause(
          recursive: false,
          ctes: [
            CommonTableExpression(
              cteTableName: 'foo',
              materializationHint: MaterializationHint.materialized,
              columnNames: ['x'],
              as: SelectStatement(columns: [StarResultColumn()]),
            ),
            CommonTableExpression(
              cteTableName: 'bar',
              materializationHint: MaterializationHint.notMaterialized,
              columnNames: ['x'],
              as: SelectStatement(columns: [StarResultColumn()]),
            ),
          ],
        ),
        columns: [StarResultColumn()],
      ),
    );
  });
}
