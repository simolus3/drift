import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';

import '../utils.dart';

void _enforceFrom(SelectStatement stmt, Queryable expected) {
  enforceHasSpan(stmt);
  enforceEqual(stmt.from, expected);
}

void main() {
  group('from', () {
    test('a simple table', () {
      final stmt =
          SqlEngine().parse('SELECT * FROM tbl').rootNode as SelectStatement;

      enforceEqual(stmt.from, TableReference('tbl', null));
    });

    test('from more than one table', () {
      final stmt = SqlEngine()
          .parse('SELECT * FROM tbl AS test, table2')
          .rootNode as SelectStatement;

      _enforceFrom(
        stmt,
        JoinClause(
          primary: TableReference('tbl', 'test'),
          joins: [
            Join(
              operator: JoinOperator.comma,
              query: TableReference('table2', null),
            ),
          ],
        ),
      );
    });

    test('more than one table with ON constraint', () {
      final stmt = SqlEngine()
          .parse('SELECT * FROM tbl AS test, table2 ON TRUE')
          .rootNode as SelectStatement;

      _enforceFrom(
        stmt,
        JoinClause(
          primary: TableReference('tbl', 'test'),
          joins: [
            Join(
              operator: JoinOperator.comma,
              query: TableReference('table2', null),
              constraint: OnConstraint(
                expression: BooleanLiteral.withTrue(token(TokenType.$true)),
              ),
            ),
          ],
        ),
      );
    });

    test('from inner select statements', () {
      final stmt = SqlEngine()
          .parse(
              'SELECT * FROM table1, (SELECT * FROM table2 WHERE a) as "inner"')
          .rootNode as SelectStatement;

      _enforceFrom(
        stmt,
        JoinClause(
          primary: TableReference('table1', null),
          joins: [
            Join(
              operator: JoinOperator.comma,
              query: SelectStatementAsSource(
                statement: SelectStatement(
                  columns: [StarResultColumn(null)],
                  from: TableReference('table2', null),
                  where: Reference(columnName: 'a'),
                ),
                as: 'inner',
              ),
            ),
          ],
        ),
      );
    });

    test('from a join', () {
      final stmt = SqlEngine()
          .parse('SELECT * FROM table1 '
              'INNER JOIN table2 USING (test) '
              'LEFT OUTER JOIN table3 ON TRUE')
          .rootNode as SelectStatement;

      _enforceFrom(
        stmt,
        JoinClause(
          primary: TableReference('table1', null),
          joins: [
            Join(
              operator: JoinOperator.inner,
              query: TableReference('table2', null),
              constraint: UsingConstraint(columnNames: ['test']),
            ),
            Join(
              operator: JoinOperator.leftOuter,
              query: TableReference('table3', null),
              constraint: OnConstraint(
                expression: BooleanLiteral.withTrue(token(TokenType.$true)),
              ),
            ),
          ],
        ),
      );
    });

    test('table valued function', () {
      testStatement(
        '''
SELECT DISTINCT user.name
  FROM user, json_each(user.phone)
WHERE json_each.value LIKE '704-%';
        ''',
        SelectStatement(
          distinct: true,
          columns: [
            ExpressionResultColumn(
              expression: Reference(tableName: 'user', columnName: 'name'),
            ),
          ],
          from: JoinClause(
            primary: TableReference('user'),
            joins: [
              Join(
                operator: JoinOperator.comma,
                query: TableValuedFunction(
                  'json_each',
                  ExprFunctionParameters(parameters: [
                    Reference(tableName: 'user', columnName: 'phone')
                  ]),
                ),
              ),
            ],
          ),
          where: StringComparisonExpression(
            left: Reference(tableName: 'json_each', columnName: 'value'),
            operator: token(TokenType.like),
            right: StringLiteral(stringLiteral('704-%')),
          ),
        ),
      );
    });
  });
}
