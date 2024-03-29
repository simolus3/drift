import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('parses VALUES select statement', () {
    testStatement(
      "VALUES ('foo', 'bar'), (1, 2)",
      ValuesSelectStatement(
        [
          Tuple(
            expressions: [
              StringLiteral('foo'),
              StringLiteral('bar'),
            ],
          ),
          Tuple(
            expressions: [
              NumericLiteral(1),
              NumericLiteral(2),
            ],
          ),
        ],
      ),
    );
  });

  test('can select FROM VALUES', () {
    testStatement(
      'SELECT * FROM (VALUES(1, 2))',
      SelectStatement(
        columns: [StarResultColumn()],
        from: SelectStatementAsSource(
          statement: ValuesSelectStatement(
            [
              Tuple(
                expressions: [
                  NumericLiteral(1),
                  NumericLiteral(2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  });

  test('can use WITH clause on VALUES', () {
    testStatement(
      'WITH foo AS (VALUES (3)) VALUES(1, 2)',
      ValuesSelectStatement(
        [
          Tuple(
            expressions: [
              NumericLiteral(1),
              NumericLiteral(2),
            ],
          ),
        ],
        withClause: WithClause(
          recursive: false,
          ctes: [
            CommonTableExpression(
              cteTableName: 'foo',
              as: ValuesSelectStatement([
                Tuple(expressions: [NumericLiteral(3)]),
              ]),
            ),
          ],
        ),
      ),
    );
  });
}
