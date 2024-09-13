import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import '../parser/utils.dart';

void main() {
  test('does not throw when parsing invalid statements', () {
    final engine = SqlEngine();
    late ParseResult result;

    try {
      result = engine.parse('UDPATE foo SET bar = foo;');
    } on ParsingError {
      fail('Calling engine.parse threw an error');
    }

    expect(result.errors, isNotEmpty);
  });

  test('does not throw when encountering tokenizer errors', () {
    final engine = SqlEngine();
    final result = engine
        .parse("SELECT * FROM foo WHERE bar = 'unterminated string literal");

    expect(result.errors,
        [isParsingError(message: contains('Unterminated string'))]);
  });

  test('does not throw when analyzing invalid statements', () {
    final engine = SqlEngine();
    late AnalysisContext result;

    try {
      result = engine.analyze('UDPATE foo SET bar = foo;');
    } on ParsingError {
      fail('Calling engine.parse threw an error');
    }

    expect(result.errors, isNotEmpty);
  });

  group('parseColumnConstraints', () {
    test('parses constraints', () {
      final result = SqlEngine()
          .parseColumnConstraints('PRIMARY KEY NOT NULL CHECK (1) DEFAULT 0');
      final parsedConstraints =
          (result.rootNode as ColumnDefinition).constraints;
      final expectedConstraints = [
        PrimaryKeyColumn(null),
        NotNull(null),
        CheckColumn(null, NumericLiteral(1)),
        Default(null, NumericLiteral(0)),
      ];

      expect(parsedConstraints, hasLength(expectedConstraints.length));
      for (var i = 0; i < expectedConstraints.length; i++) {
        enforceHasSpan(parsedConstraints[i]);
        enforceEqual(parsedConstraints[i], expectedConstraints[i]);
      }
    });

    test('parses until error', () {
      final result = SqlEngine().parseColumnConstraints(
          'PRIMARY KEY NOT NULL invalid syntax CHECK (1)');
      final parsedConstraints =
          (result.rootNode as ColumnDefinition).constraints;

      expect(parsedConstraints, hasLength(2));
      expect(result.errors, [
        isA<ParsingError>().having(
            (e) => e.message, 'message', contains('Expected a constraint')),
      ]);
    });

    test('never allows drift extensions', () {
      final result =
          SqlEngine(EngineOptions(driftOptions: const DriftSqlOptions()))
              .parseColumnConstraints('MAPPED BY `myconverter()`');
      expect(result.errors, [
        isA<ParsingError>().having(
            (e) => e.message, 'message', contains('Expected a constraint')),
      ]);
    });
  });

  group('parseTableConstraint', () {
    test('parses constraint', () {
      final result = SqlEngine().parseTableConstraint(
          'CONSTRAINT foo FOREIGN KEY (a, b) REFERENCES c (d, e);');
      expect(result.errors, isEmpty);

      enforceEqual(
        result.rootNode,
        ForeignKeyTableConstraint(
          'foo',
          columns: [
            Reference(columnName: 'a'),
            Reference(columnName: 'b'),
          ],
          clause: ForeignKeyClause(
            foreignTable: TableReference('c'),
            columnNames: [
              Reference(columnName: 'd'),
              Reference(columnName: 'e'),
            ],
          ),
        ),
      );
    });

    test('report errors', () {
      final result = SqlEngine().parseTableConstraint('parse error');
      expect(result.errors, isNotEmpty);
    });
  });
}
