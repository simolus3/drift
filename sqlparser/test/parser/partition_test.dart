import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import 'utils.dart';

final Map<String, Expression> _testCases = {
  'row_number() OVER (ORDER BY y)': AggregateExpression(
    function: identifier('row_number'),
    parameters: ExprFunctionParameters(),
    windowDefinition: WindowDefinition(
      frameSpec: FrameSpec(),
      orderBy: OrderBy(terms: [
        OrderingTerm(expression: Reference(columnName: 'y')),
      ]),
    ),
  ),
  'row_number(*) FILTER (WHERE 1) OVER '
          '(base_name PARTITION BY a, b '
          'GROUPS BETWEEN UNBOUNDED PRECEDING AND 3 FOLLOWING EXCLUDE TIES)':
      AggregateExpression(
    function: identifier('row_number'),
    parameters: const StarFunctionParameter(),
    filter: NumericLiteral(1, token(TokenType.numberLiteral)),
    windowDefinition: WindowDefinition(
      baseWindowName: 'base_name',
      partitionBy: [
        Reference(columnName: 'a'),
        Reference(columnName: 'b'),
      ],
      frameSpec: FrameSpec(
        type: FrameType.groups,
        start: const FrameBoundary.unboundedPreceding(),
        end: FrameBoundary.following(
          NumericLiteral(3, token(TokenType.numberLiteral)),
        ),
        excludeMode: ExcludeMode.ties,
      ),
    ),
  ),
  'row_number() OVER (RANGE CURRENT ROW EXCLUDE NO OTHERS)':
      AggregateExpression(
    function: identifier('row_number'),
    parameters: ExprFunctionParameters(),
    windowDefinition: WindowDefinition(
      frameSpec: FrameSpec(
        type: FrameType.range,
        start: const FrameBoundary.currentRow(),
        end: const FrameBoundary.currentRow(),
        excludeMode: ExcludeMode.noOthers,
      ),
    ),
  ),
};

void main() {
  group('partition parses', () {
    _testCases.forEach((sql, expected) {
      test(sql, () {
        final scanner = Scanner(sql);
        final tokens = scanner.scanTokens();
        final parser = Parser(tokens);
        final expression = parser.expression();
        enforceEqual(expression, expected);
      });
    });
  });
}
