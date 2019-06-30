import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

export 'package:sqlparser/src/reader/tokenizer/token.dart';

Token token(TokenType type) {
  return Token(type, null);
}

void testStatement(String sql, AstNode expected) {
  final parsed = SqlEngine().parse(sql).rootNode;
  enforceEqual(parsed, expected);
}

void testAll(Map<String, AstNode> testCases) {
  testCases.forEach((sql, expected) {
    test('with $sql', () {
      testStatement(sql, expected);
    });
  });
}
