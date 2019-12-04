import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';
import 'utils.dart';

final Map<String, AstNode> testCases = {
  'UPDATE OR ROLLBACK tbl SET a = NULL, b = c WHERE d': UpdateStatement(
    or: FailureMode.rollback,
    table: TableReference('tbl', null),
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
}
