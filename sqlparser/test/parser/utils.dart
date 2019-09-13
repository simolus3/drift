import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

export 'package:sqlparser/src/reader/tokenizer/token.dart';

Token token(TokenType type) {
  return Token(type, null);
}

InlineDartToken inlineDart(String dartCode) {
  return InlineDartToken(fakeSpan('`$dartCode`'));
}

IdentifierToken identifier(String content) {
  return IdentifierToken(false, fakeSpan(content));
}

void testStatement(String sql, AstNode expected) {
  final parsed = SqlEngine().parse(sql).rootNode;
  enforceEqual(parsed, expected);
}

FileSpan fakeSpan(String content) {
  return SourceFile.fromString(content).span(0);
}

void testAll(Map<String, AstNode> testCases) {
  testCases.forEach((sql, expected) {
    test('with $sql', () {
      testStatement(sql, expected);
    });
  });
}
