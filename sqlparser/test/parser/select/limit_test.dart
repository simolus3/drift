import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';

import '../utils.dart';

void main() {
  group('limit clauses', () {
    test('with just a limit', () {
      final select = SqlEngine().parse('SELECT * FROM test LIMIT 5 * 3')
          as SelectStatement;

      enforceEqual(
        select.limit,
        Limit(
          count: BinaryExpression(
            NumericLiteral(5, token(TokenType.numberLiteral)),
            token(TokenType.star),
            NumericLiteral(3, token(TokenType.numberLiteral)),
          ),
        ),
      );
    });

    test('with offset', () {
      final select = SqlEngine().parse('SELECT * FROM test LIMIT 10 OFFSET 2')
          as SelectStatement;

      enforceEqual(
        select.limit,
        Limit(
          count: NumericLiteral(10, token(TokenType.numberLiteral)),
          offsetSeparator: token(TokenType.offset),
          offset: NumericLiteral(2, token(TokenType.numberLiteral)),
        ),
      );
    });

    test('with offset as comma', () {
      final select = SqlEngine().parse('SELECT * FROM test LIMIT 10, 2')
          as SelectStatement;

      enforceEqual(
        select.limit,
        Limit(
          count: NumericLiteral(10, token(TokenType.numberLiteral)),
          offsetSeparator: token(TokenType.comma),
          offset: NumericLiteral(2, token(TokenType.numberLiteral)),
        ),
      );
    });
  });
}
