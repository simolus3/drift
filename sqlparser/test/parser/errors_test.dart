import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('WITH without following statement', () {
    expectError('WITH foo AS (SELECT * FROM bar)',
        [isParsingError(message: contains('to follow this WITH clause'))]);
  });

  group('when using keywords', () {
    test('for function calls', () {
      expectError('SELECT replace(a, b, c);', [
        isParsingError(
          message: contains('Did you mean to call a function?'),
          lexeme: 'replace',
        ),
      ]);
    });

    test('as identifiers', () {
      expectError('SELECT group FROM foo;', [
        isParsingError(
          message: contains('Did you mean to use it as a column?'),
          lexeme: 'group',
        ),
      ]);

      expectError('CREATE TABLE x (table TEXT NOT NULL, foo INTEGER);', [
        isParsingError(
          message: 'Expected a column name (got keyword TABLE)',
          lexeme: 'table',
        ),
      ]);
    });
  });
}

void expectError(String sql, errorsMatcher) {
  final parsed = SqlEngine().parse(sql);

  expect(parsed.errors, errorsMatcher);
}

TypeMatcher<ParsingError> isParsingError({message, lexeme}) {
  var matcher = isA<ParsingError>();

  if (lexeme != null) {
    matcher = matcher.having((e) => e.token.lexeme, 'token.lexeme', lexeme);
  }

  if (message != null) {
    matcher = matcher.having((e) => e.message, 'message', message);
  }

  return matcher;
}
