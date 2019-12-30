import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';

import '../utils.dart';

void _enforceFrom(SelectStatement stmt, List<Queryable> expected) {
  enforceHasSpan(stmt);
  expect(stmt.from.length, expected.length);

  for (var i = 0; i < stmt.from.length; i++) {
    enforceEqual(stmt.from[i], expected[i]);
  }
}

void main() {
  group('from', () {
    test('a simple table', () {
      final stmt =
          SqlEngine().parse('SELECT * FROM tbl').rootNode as SelectStatement;

      enforceEqual(stmt.from.single, TableReference('tbl', null));
    });

    test('from more than one table', () {
      final stmt = SqlEngine()
          .parse('SELECT * FROM tbl AS test, table2')
          .rootNode as SelectStatement;

      _enforceFrom(
        stmt,
        [
          TableReference('tbl', 'test'),
          TableReference('table2', null),
        ],
      );
    });

    test('from inner select statements', () {
      final stmt = SqlEngine()
          .parse(
              'SELECT * FROM table1, (SELECT * FROM table2 WHERE a) as "inner"')
          .rootNode as SelectStatement;

      _enforceFrom(
        stmt,
        [
          TableReference('table1', null),
          SelectStatementAsSource(
            statement: SelectStatement(
              columns: [StarResultColumn(null)],
              from: [TableReference('table2', null)],
              where: Reference(columnName: 'a'),
            ),
            as: 'inner',
          ),
        ],
      );
    });

    test('from a join', () {
      final stmt = SqlEngine()
          .parse('SELECT * FROM table1 '
              'INNER JOIN table2 USING (test) '
              'LEFT OUTER JOIN table3 ON TRUE')
          .rootNode as SelectStatement;

      _enforceFrom(stmt, [
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
      ]);
    });
  });
}
