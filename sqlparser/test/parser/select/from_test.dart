import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import '../utils.dart';

void _enforceFrom(SelectStatement stmt, Queryable expected) {
  enforceHasSpan(stmt);
  enforceEqual(stmt.from!, expected);
}

void main() {
  group('from', () {
    test('a simple table', () {
      final stmt =
          SqlEngine().parse('SELECT * FROM tbl').rootNode as SelectStatement;

      _enforceFrom(stmt, TableReference('tbl'));
    });

    test('schema name and alias', () {
      final stmt = SqlEngine().parse('SELECT * FROM main.tbl foo').rootNode
          as SelectStatement;
      _enforceFrom(stmt, TableReference('tbl', schemaName: 'main', as: 'foo'));
    });

    test('from more than one table', () {
      final stmt = SqlEngine()
          .parse('SELECT * FROM tbl AS test, table2')
          .rootNode as SelectStatement;

      _enforceFrom(
        stmt,
        JoinClause(
          primary: TableReference('tbl', as: 'test'),
          joins: [
            Join(
              operator: JoinOperator.comma(),
              query: TableReference('table2'),
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
          primary: TableReference('tbl', as: 'test'),
          joins: [
            Join(
              operator: JoinOperator.comma(),
              query: TableReference('table2'),
              constraint: OnConstraint(
                expression: BooleanLiteral.withTrue(token(TokenType.$true)),
              ),
            ),
          ],
        ),
      );
    });

    test('inner select statements', () {
      final stmt = SqlEngine()
          .parse(
              'SELECT * FROM table1, (SELECT * FROM table2 WHERE a) as "inner"')
          .rootNode as SelectStatement;

      _enforceFrom(
        stmt,
        JoinClause(
          primary: TableReference('table1'),
          joins: [
            Join(
              operator: JoinOperator.comma(),
              query: SelectStatementAsSource(
                statement: SelectStatement(
                  columns: [StarResultColumn(null)],
                  from: TableReference('table2'),
                  where: Reference(columnName: 'a'),
                ),
                as: 'inner',
              ),
            ),
          ],
        ),
      );
    });

    test('inner compound select statements', () {
      final stmt = SqlEngine()
          .parse('SELECT SUM(*) FROM (SELECT COUNT(*) FROM table1 UNION ALL '
              'SELECT COUNT(*) from table2)')
          .rootNode as SelectStatement;

      final countStar = ExpressionResultColumn(
        expression: FunctionExpression(
          name: 'COUNT',
          parameters: StarFunctionParameter(),
        ),
      );

      _enforceFrom(
        stmt,
        SelectStatementAsSource(
          statement: CompoundSelectStatement(
            base: SelectStatement(
              columns: [countStar],
              from: TableReference('table1'),
            ),
            additional: [
              CompoundSelectPart(
                mode: CompoundSelectMode.unionAll,
                select: SelectStatement(
                  columns: [countStar],
                  from: TableReference('table2'),
                ),
              ),
            ],
          ),
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
          primary: TableReference('table1'),
          joins: [
            Join(
              operator: JoinOperator(JoinOperatorKind.inner),
              query: TableReference('table2'),
              constraint: UsingConstraint(columnNames: ['test']),
            ),
            Join(
              operator: JoinOperator(JoinOperatorKind.left, outer: true),
              query: TableReference('table3'),
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
              expression: Reference(entityName: 'user', columnName: 'name'),
            ),
          ],
          from: JoinClause(
            primary: TableReference('user'),
            joins: [
              Join(
                operator: JoinOperator.comma(),
                query: TableValuedFunction(
                  'json_each',
                  ExprFunctionParameters(parameters: [
                    Reference(entityName: 'user', columnName: 'phone')
                  ]),
                ),
              ),
            ],
          ),
          where: StringComparisonExpression(
            left: Reference(entityName: 'json_each', columnName: 'value'),
            operator: token(TokenType.like),
            right: StringLiteral(stringLiteral('704-%')),
          ),
        ),
      );
    });
  });

  group('join kinds', () {
    SelectStatement selectWith(Queryable from) {
      return SelectStatement(
        columns: [StarResultColumn()],
        from: from,
      );
    }

    test('comma', () {
      testStatement(
        'SELECT * FROM foo, bar',
        selectWith(
          JoinClause(primary: TableReference('foo'), joins: [
            Join(operator: JoinOperator.comma(), query: TableReference('bar'))
          ]),
        ),
      );
    });

    test('none', () {
      testStatement(
        'SELECT * FROM foo JOIN bar',
        selectWith(
          JoinClause(primary: TableReference('foo'), joins: [
            Join(
                operator: JoinOperator(JoinOperatorKind.none),
                query: TableReference('bar'))
          ]),
        ),
      );
    });

    test('natural none', () {
      testStatement(
        'SELECT * FROM foo NATURAL JOIN bar',
        selectWith(
          JoinClause(primary: TableReference('foo'), joins: [
            Join(
                operator: JoinOperator(JoinOperatorKind.none, natural: true),
                query: TableReference('bar'))
          ]),
        ),
      );
    });

    test('cross', () {
      testStatement(
        'SELECT * FROM foo CROSS JOIN bar',
        selectWith(
          JoinClause(primary: TableReference('foo'), joins: [
            Join(
                operator: JoinOperator(JoinOperatorKind.cross),
                query: TableReference('bar'))
          ]),
        ),
      );
    });

    for (final natural in [true, false]) {
      group('with natural: $natural', () {
        final naturalText = natural ? 'NATURAL' : '';

        test('inner', () {
          testStatement(
            'SELECT * FROM foo $naturalText INNER JOIN bar',
            selectWith(
              JoinClause(primary: TableReference('foo'), joins: [
                Join(
                  operator: JoinOperator(
                    JoinOperatorKind.inner,
                    natural: natural,
                  ),
                  query: TableReference('bar'),
                )
              ]),
            ),
          );
        });

        for (final outer in [true, false]) {
          final outerText = outer ? 'OUTER' : '';
          const kinds = {
            'LEFT': JoinOperatorKind.left,
            'RIGHT': JoinOperatorKind.right,
            'FULL': JoinOperatorKind.full,
          };

          group('with outer: $outer', () {
            kinds.forEach((text, operatorKind) {
              test('operator $text', () {
                testStatement(
                  'SELECT * FROM foo $naturalText $text $outerText JOIN bar',
                  selectWith(
                    JoinClause(primary: TableReference('foo'), joins: [
                      Join(
                        operator: JoinOperator(
                          operatorKind,
                          natural: natural,
                          outer: outer,
                        ),
                        query: TableReference('bar'),
                      )
                    ]),
                  ),
                );
              });
            });
          });
        }
      });
    }

    test('does not allow natural with comma', () {
      expectParseError('SELECT * FROM foo NATURAL, bar', span: ',');
    });

    test('does not allow natural with cross', () {
      expectParseError('SELECT * FROM foo NATURAL CROSS JOIN bar',
          span: 'CROSS');
    });

    test('does not allow INNER OUTER', () {
      expectParseError('SELECT * FROM foo INNER OUTER CROSS JOIN bar',
          span: 'OUTER');
    });
  });
}
