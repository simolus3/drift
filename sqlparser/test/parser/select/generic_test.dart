import 'package:sqlparser/src/ast/ast.dart';
import '../utils.dart';

final Map<String, AstNode> testCases = {
  'SELECT table.*, *, 1 as name WHERE 1 ORDER BY name LIMIT 3 OFFSET 5':
      SelectStatement(
    columns: [
      StarResultColumn('table'),
      StarResultColumn(null),
      ExpressionResultColumn(
        expression: NumericLiteral(1, token(TokenType.numberLiteral)),
        as: 'name',
      ),
    ],
    where: NumericLiteral(1, token(TokenType.numberLiteral)),
    orderBy: OrderBy(terms: [
      OrderingTerm(expression: Reference(columnName: 'name')),
    ]),
    limit: Limit(
      count: NumericLiteral(3, token(TokenType.numberLiteral)),
      offsetSeparator: token(TokenType.offset),
      offset: NumericLiteral(5, token(TokenType.numberLiteral)),
    ),
  ),
  'SELECT table.*, (SELECT * FROM table2) FROM table': SelectStatement(
    columns: [
      StarResultColumn('table'),
      ExpressionResultColumn(
        expression: SubQuery(
          select: SelectStatement(
            columns: [StarResultColumn(null)],
            from: [TableReference('table2', null)],
          ),
        ),
      ),
    ],
    from: [
      TableReference('table', null),
    ],
  ),
  'SELECT * FROM table WHERE id IN ()': SelectStatement(
    columns: [StarResultColumn(null)],
    from: [TableReference('table', null)],
    where: InExpression(
      left: Reference(columnName: 'id'),
      inside: TupleExpression(expressions: []),
    ),
  ),
};

void main() {
  testAll(testCases);
}
