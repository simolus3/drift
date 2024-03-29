import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('parses compound select statements', () {
    testStatement(
      'SELECT * FROM tbl UNION ALL SELECT 1 EXCEPT SELECT 2',
      CompoundSelectStatement(
        base: SelectStatement(
          columns: [StarResultColumn(null)],
          from: TableReference('tbl'),
        ),
        additional: [
          CompoundSelectPart(
            mode: CompoundSelectMode.unionAll,
            select: SelectStatement(
              columns: [
                ExpressionResultColumn(
                  expression: NumericLiteral(1),
                ),
              ],
            ),
          ),
          CompoundSelectPart(
            mode: CompoundSelectMode.except,
            select: SelectStatement(
              columns: [
                ExpressionResultColumn(
                  expression: NumericLiteral(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}
