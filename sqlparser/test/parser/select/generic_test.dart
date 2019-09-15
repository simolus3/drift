import 'package:sqlparser/src/ast/ast.dart';
import '../utils.dart';

final Map<String, AstNode> testCases = {
  'SELECT tbl.*, *, 1 as name WHERE 1 ORDER BY name ASC LIMIT 3 OFFSET 5':
      SelectStatement(
    columns: [
      StarResultColumn('tbl'),
      StarResultColumn(null),
      ExpressionResultColumn(
        expression: NumericLiteral(1, token(TokenType.numberLiteral)),
        as: 'name',
      ),
    ],
    where: NumericLiteral(1, token(TokenType.numberLiteral)),
    orderBy: OrderBy(terms: [
      OrderingTerm(
        expression: Reference(columnName: 'name'),
        orderingMode: OrderingMode.ascending,
      ),
    ]),
    limit: Limit(
      count: NumericLiteral(3, token(TokenType.numberLiteral)),
      offsetSeparator: token(TokenType.offset),
      offset: NumericLiteral(5, token(TokenType.numberLiteral)),
    ),
  ),
  'SELECT tbl.*, (SELECT * FROM table2) FROM tbl': SelectStatement(
    columns: [
      StarResultColumn('tbl'),
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
      TableReference('tbl', null),
    ],
  ),
  'SELECT * FROM tbl WHERE id IN ()': SelectStatement(
    columns: [StarResultColumn(null)],
    from: [TableReference('tbl', null)],
    where: InExpression(
      left: Reference(columnName: 'id'),
      inside: Tuple(expressions: []),
    ),
  ),
};

void main() {
  testAll(testCases);
}
