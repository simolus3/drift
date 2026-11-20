import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:test/test.dart';

import '../parser/utils.dart';

void expectFullToken(String token, TokenType type) {
  final tokens = SqlEngine().tokenizeString(token);

  if (tokens.length != 2 || tokens.last.type != TokenType.eof) {
    fail(
      'Expected exactly one token when parsing $token, '
      'got ${tokens.length - 1}',
    );
  }

  expect(tokens.first.type, type, reason: '$token is a $type');
  expect(tokens.first.span.text, token);
}

Map<String, TokenType> testCases = {
  '(': TokenType.leftParen,
  ')': TokenType.rightParen,
  ',': TokenType.comma,
  '.': TokenType.dot,
  '+': TokenType.plus,
  '-': TokenType.minus,
  '*': TokenType.star,
  '/': TokenType.slash,
  '<=': TokenType.lessEqual,
  '<': TokenType.less,
  '>=': TokenType.moreEqual,
  '>': TokenType.more,
  '!=': TokenType.exclamationEqual,
  "'hello there'": TokenType.stringLiteral,
  "''": TokenType.stringLiteral,
  '1.123': TokenType.numberLiteral,
  '1.32e5': TokenType.numberLiteral,
  '.123e-3': TokenType.numberLiteral,
  '0xFF13': TokenType.numberLiteral,
  '0Xf13A': TokenType.numberLiteral,
  'SELECT': TokenType.select,
  '"UPDATE"': TokenType.identifier,
  '@foo': TokenType.atSignVariable,
  ':named': TokenType.colonVariable,
  '"spo\uD83C\uDF83ky"': TokenType.identifier,
  '[account name]': TokenType.identifier,
};

void main() {
  group('single token:', () {
    for (final entry in testCases.entries) {
      test('parses ${entry.key}', () {
        expectFullToken(entry.key, entry.value);
      });
    }
  });

  test('can escape strings', () {
    final tokens = SqlEngine().tokenizeString("'what''s up'");

    expect(tokens, hasLength(2)); // eof token at the end
    expect(
      tokens.first,
      const TypeMatcher<StringLiteralToken>().having(
        (token) => token.value,
        'value',
        "what's up",
      ),
    );
    expect(tokens[1].type, TokenType.eof);
  });

  group("parse unterminated string literals", () {
    Scanner defaultScanner(FileSpan span) {
      return Scanner(
        span,
        scanDriftTokens: false,
        scanDoubleColonTokens: false,
      );
    }

    test('issues error', () {
      final scanner = defaultScanner(fakeSpan("'unterminated"));
      final token = scanner.scanToken();

      expect(
        scanner.errors,
        contains(
          const TypeMatcher<TokenizerError>().having(
            (e) => e.message,
            'message',
            'Unterminated string',
          ),
        ),
      );

      expect(
        token,
        isA<StringLiteralToken>().having(
          (e) => e.value,
          'value',
          'unterminated',
        ),
      );
      expect(scanner.scanToken().type, TokenType.eof);
    });

    test('does not crash if the input ends with apostrophe', () {
      final scanner = defaultScanner(fakeSpan("'"));
      scanner.scanToken();

      expect(
        scanner.errors,
        contains(
          const TypeMatcher<TokenizerError>().having(
            (e) => e.message,
            'message',
            'Unterminated string',
          ),
        ),
      );
    });
  });

  test('binary string literal', () {
    final tokens = SqlEngine().tokenizeString("X'1234' x'5678'");

    expect(tokens, hasLength(3));
    expect(
      tokens[0],
      const TypeMatcher<StringLiteralToken>()
          .having((token) => token.binary, 'binary', isTrue)
          .having((token) => token.value, 'value', '1234'),
    );
    expect(
      tokens[1],
      const TypeMatcher<StringLiteralToken>()
          .having((token) => token.binary, 'binary', isTrue)
          .having((token) => token.value, 'value', '5678'),
    );
    expect(tokens[2].type, TokenType.eof);
  });

  group('parses numeric literals', () {
    void checkLiteral(String lexeme, NumericToken other, num value) {
      final tokens = SqlEngine().tokenizeString(lexeme);
      final token = tokens.first as NumericToken;

      expect(
        token.hasSameStructureAs(other),
        isTrue,
        reason: '$token should have the same structure as $other',
      );

      expect(token.parsedNumber, equals(value));
    }

    test('hexadecimal', () {
      checkLiteral(
        '0x123',
        NumericToken.hexadecimal(defaultSpan, '123'),
        0x123,
      );
      checkLiteral(
        '0x12_34',
        NumericToken.hexadecimal(defaultSpan, '1234'),
        0x1234,
      );

      expect(
        () => SqlEngine().tokenizeString('0x'),
        throwsA(isA<CumulatedTokenizerException>()),
      );
    });

    test('integer without exponent', () {
      checkLiteral(
        '42',
        NumericToken(defaultSpan, digitsBeforeDecimal: '42'),
        42,
      );
      checkLiteral(
        '4_2',
        NumericToken(defaultSpan, digitsBeforeDecimal: '42'),
        42,
      );
    });

    test('integer, positive exponent', () {
      checkLiteral(
        '42E1',
        NumericToken(defaultSpan, digitsBeforeDecimal: '42', exponent: 1),
        420,
      );
    });

    test('integer, negative exponent', () {
      checkLiteral(
        '42E-1',
        NumericToken(defaultSpan, digitsBeforeDecimal: '42', exponent: -1),
        4.2,
      );
      checkLiteral(
        '42E-1_0',
        NumericToken(defaultSpan, digitsBeforeDecimal: '42', exponent: -10),
        4.2e-9,
      );
    });

    // Any literal with a decimal point or an exponent is a REAL in SQLite.
    // https://sqlite.org/lang_expr.html#literal_values_constants_
    test('literals with an exponent or decimal point are doubles', () {
      void expectDouble(String lexeme, double value) {
        final token = SqlEngine().tokenizeString(lexeme).first as NumericToken;
        expect(token.parsedNumber, isA<double>(), reason: lexeme);
        expect(token.parsedNumber, value, reason: lexeme);
      }

      expectDouble('1e5', 100000.0);
      expectDouble('1E5', 100000.0);
      expectDouble('1e+5', 100000.0);
      expectDouble('1e-5', 0.00001);
      expectDouble('1.0e2', 100.0);
      expectDouble('.5e1', 5.0);
      expectDouble('5.', 5.0);
      expectDouble('1e0', 1.0);
      expectDouble('1e30', 1e30);
      expectDouble('1e23', 1e23);
      expectDouble('1_000e2', 100000.0);
      expectDouble('.41e24', 4.1e23);
    });

    test('literals without exponent or decimal point stay integers', () {
      void expectInt(String lexeme, int value) {
        final token = SqlEngine().tokenizeString(lexeme).first as NumericToken;
        expect(token.parsedNumber, isA<int>(), reason: lexeme);
        expect(token.parsedNumber, value, reason: lexeme);
      }

      expectInt('15', 15);
      expectInt('0x1F', 0x1F);
      expectInt('0', 0);
      expectInt('0X1f', 0x1F);
    });

    test('decimal literals without exponent stay doubles', () {
      final decimal = SqlEngine().tokenizeString('1.5').first as NumericToken;
      expect(decimal.parsedNumber, isA<double>());
      expect(decimal.parsedNumber, 1.5);
      final leadingDot = SqlEngine().tokenizeString('.5').first as NumericToken;
      expect(leadingDot.parsedNumber, isA<double>());
      expect(leadingDot.parsedNumber, 0.5);
    });

    test('missing number after exponent', () {
      expect(
        () => SqlEngine().tokenizeString('1e+'),
        throwsA(isA<CumulatedTokenizerException>()),
      );
      expect(
        () => SqlEngine().tokenizeString('1e-x'),
        throwsA(isA<CumulatedTokenizerException>()),
      );
    });

    test('decimal', () {
      checkLiteral(
        '4.2',
        NumericToken(
          defaultSpan,
          digitsBeforeDecimal: '4',
          digitsAfterDecimal: '2',
          hasDecimalPoint: true,
        ),
        4.2,
      );

      checkLiteral(
        '4_3.2_1',
        NumericToken(
          defaultSpan,
          digitsBeforeDecimal: '43',
          digitsAfterDecimal: '21',
          hasDecimalPoint: true,
        ),
        43.21,
      );
    });

    test('decimal, nothing after decimal dot', () {
      checkLiteral(
        '4.e2',
        NumericToken(
          defaultSpan,
          digitsBeforeDecimal: '4',
          exponent: 2,
          hasDecimalPoint: true,
        ),
        400.0,
      );
    });

    test('decimal, nothing before decimal dot', () {
      checkLiteral(
        '.2',
        NumericToken(
          defaultSpan,
          digitsAfterDecimal: '2',
          hasDecimalPoint: true,
        ),
        .2,
      );
    });
  });

  test('named variables', () {
    for (final prefix in [':', '@', r'$']) {
      final tokens = SqlEngine().tokenizeString('${prefix}name');
      final token = tokens[0] as NamedVariableToken;

      expect(token.name, 'name');
      expect(token.fullName, '${prefix}name');
    }
  });
}
