import 'package:collection/collection.dart' show IterableExtension;
import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

export 'package:sqlparser/src/reader/tokenizer/token.dart';

final defaultSpan = fakeSpan('fake');

Token token(TokenType type) {
  return Token(type, defaultSpan);
}

StringLiteralToken stringLiteral(String value) {
  return StringLiteralToken(value, defaultSpan);
}

InlineDartToken inlineDart(String dartCode) {
  return InlineDartToken(fakeSpan('`$dartCode`'));
}

IdentifierToken identifier(String content) {
  return IdentifierToken(false, fakeSpan(content));
}

DriftFile parseDrift(String content) {
  return SqlEngine(
    EngineOptions(driftOptions: const DriftSqlOptions()),
  ).parse(ParserEntrypoint.driftFile, content).rootNode;
}

void testDriftFile(String driftFile, DriftFile expected) {
  final parsed = parseDrift(driftFile);
  enforceHasSpan(parsed);
  enforceEqual(parsed, expected);
}

void testStatement(String sql, AstNode expected, {bool driftMode = false}) {
  final parsed = parseStatement(sql, driftMode: driftMode);
  enforceHasSpan(parsed);
  enforceEqual(parsed, expected);
}

Statement parseStatement(String sql, {bool driftMode = false}) {
  final result = SqlEngine(
    EngineOptions(driftOptions: driftMode ? const DriftSqlOptions() : null),
  ).parse(ParserEntrypoint.statement, sql);
  expect(result.errors, isEmpty);

  return result.rootNode;
}

void expectParseError(
  String sql, {
  dynamic message = anything,
  dynamic span = anything,
}) {
  final result = SqlEngine().parse(ParserEntrypoint.statement, sql);

  expect(result.errors, [isParsingError(message: message, span: span)]);
}

TypeMatcher<ParsingError> isParsingError({
  dynamic message = anything,
  dynamic span = anything,
}) {
  return isA<ParsingError>()
      .having((e) => e.message, 'message', wrapMatcher(message))
      .having((e) => e.token.span.text, 'span', wrapMatcher(span));
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

/// The parser should make sure [AstNode.hasSpan] is true on relevant nodes.
void enforceHasSpan(AstNode node) {
  for (final node in [node].followedBy(node.allDescendants)) {
    if (!node.hasSpan && !node.synthetic) {
      throw ArgumentError('Node $node did not have a span');
    }

    void checkHasToken(Object? property, Token? token, String name) {
      if ((property == null) != (token == null)) {
        throw ArgumentError(
          'Node $node: $name must have both token and property set or none.',
        );
      }
    }

    if (node is Reference) {
      checkHasToken(node.schemaName, node.schemaNameToken, 'schemaName');
      checkHasToken(node.entityName, node.entityNameToken, 'entityName');
      checkHasToken(node.columnName, node.columnNameToken, 'columnName');
    }

    if (node is TableReference) {
      checkHasToken(node.schemaName, node.schemaNameToken, 'schemaName');
      checkHasToken(node.tableName, node.tableNameToken, 'tableName');
    }

    if (node is StarResultColumn) {
      checkHasToken(node.tableName, node.tableNameToken, 'tableName');
    }
  }

  final problematic = [node]
      .followedBy(node.allDescendants)
      .firstWhereOrNull((node) => !node.hasSpan && !node.synthetic);

  if (problematic != null) {
    throw ArgumentError('Node $problematic did not have a span');
  }
}
