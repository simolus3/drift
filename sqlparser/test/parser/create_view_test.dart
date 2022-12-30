import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('parses a simple create view statement', () {
    testStatement(
      'CREATE VIEW my_view AS SELECT * FROM my_tbl',
      CreateViewStatement(
        viewName: 'my_view',
        query: SelectStatement(
          columns: <ResultColumn>[StarResultColumn()],
          from: TableReference('my_tbl'),
        ),
      ),
    );
  });

  test('parses a CREATE VIEW statement with an existing Dart class', () {
    testStatement(
      'CREATE VIEW my_view WITH ExistingDartClass AS SELECT 1',
      CreateViewStatement(
        viewName: 'my_view',
        query: SelectStatement(
          columns: [
            ExpressionResultColumn(expression: NumericLiteral(1)),
          ],
        ),
        driftTableName: DriftTableName('ExistingDartClass', true),
      ),
      driftMode: true,
    );
  });

  test('parses a complex CREATE View statement', () {
    testStatement(
      'CREATE VIEW IF NOT EXISTS my_complex_view (ids, name, count, type) AS '
      'SELECT group_concat(id), name, count(*),\'dog\' FROM dogs GROUP BY name'
      ' UNION '
      'SELECT group_concat(id), name, count(*),\'cat\' FROM cats GROUP BY name',
      CreateViewStatement(
        viewName: 'my_complex_view',
        columns: ['ids', 'name', 'count', 'type'],
        ifNotExists: true,
        query: CompoundSelectStatement(
          base: SelectStatement(
            columns: [
              ExpressionResultColumn(
                expression: FunctionExpression(
                  name: 'group_concat',
                  parameters: ExprFunctionParameters(
                    parameters: [Reference(columnName: 'id')],
                  ),
                ),
              ),
              ExpressionResultColumn(
                expression: Reference(columnName: 'name'),
              ),
              ExpressionResultColumn(
                expression: FunctionExpression(
                  name: 'count',
                  parameters: StarFunctionParameter(),
                ),
              ),
              ExpressionResultColumn(
                expression: StringLiteral('dog'),
              ),
            ],
            from: TableReference('dogs'),
            groupBy: GroupBy(
              by: [Reference(columnName: 'name')],
            ),
          ),
          additional: [
            CompoundSelectPart(
              mode: CompoundSelectMode.union,
              select: SelectStatement(
                columns: [
                  ExpressionResultColumn(
                    expression: FunctionExpression(
                      name: 'group_concat',
                      parameters: ExprFunctionParameters(
                        parameters: [Reference(columnName: 'id')],
                      ),
                    ),
                  ),
                  ExpressionResultColumn(
                    expression: Reference(columnName: 'name'),
                  ),
                  ExpressionResultColumn(
                    expression: FunctionExpression(
                      name: 'count',
                      parameters: StarFunctionParameter(),
                    ),
                  ),
                  ExpressionResultColumn(expression: StringLiteral('cat'))
                ],
                from: TableReference('cats'),
                groupBy: GroupBy(
                  by: [Reference(columnName: 'name')],
                ),
              ),
            )
          ],
        ),
      ),
    );
  });
}
