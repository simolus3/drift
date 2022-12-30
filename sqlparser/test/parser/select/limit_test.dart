import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('limit clauses', () {
    test('with just a limit', () {
      final select = SqlEngine()
          .parse('SELECT * FROM test LIMIT 5 * 3')
          .rootNode as SelectStatement;

      enforceHasSpan(select);
      enforceEqual(
        select.limit!,
        Limit(
          count: BinaryExpression(
            NumericLiteral(5),
            token(TokenType.star),
            NumericLiteral(3),
          ),
        ),
      );
    });

    test('with offset', () {
      final select = SqlEngine()
          .parse('SELECT * FROM test LIMIT 10 OFFSET 2')
          .rootNode as SelectStatement;

      enforceHasSpan(select);
      enforceEqual(
        select.limit!,
        Limit(
          count: NumericLiteral(10),
          offsetSeparator: token(TokenType.offset),
          offset: NumericLiteral(2),
        ),
      );
    });

    test('with offset as comma', () {
      // with the comma notation, the offset comes first.
      // https://www.sqlite.org/lang_select.html#limitoffset
      final select = SqlEngine()
          .parse('SELECT * FROM test LIMIT 10, 2')
          .rootNode as SelectStatement;

      enforceHasSpan(select);
      enforceEqual(
        select.limit!,
        Limit(
          count: NumericLiteral(2),
          offsetSeparator: token(TokenType.comma),
          offset: NumericLiteral(10),
        ),
      );
    });
  });
}
