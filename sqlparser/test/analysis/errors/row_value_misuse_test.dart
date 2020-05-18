import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  SqlEngine engine;
  setUp(() {
    engine = SqlEngine();
  });

  test('when using row value in select', () {
    engine.analyze('SELECT (1, 2, 3)').expectError('(1, 2, 3)');
  });

  test('as left hand operator of in', () {
    engine.analyze('SELECT (1, 2, 3) IN (4, 5, 6)').expectError('(1, 2, 3)');
  });

  test('in BETWEEN expression', () {
    engine.analyze('SELECT 1 BETWEEN (1, 2, 3) AND 3').expectError('(1, 2, 3)');
  });

  test('in CASE - value', () {
    engine
        .analyze('SELECT CASE 1 WHEN 1 THEN (1, 2, 3) ELSE 1 END')
        .expectError('(1, 2, 3)');
  });

  test('in CASE - when', () {
    engine
        .analyze('SELECT CASE 1 WHEN (1, 2, 3) THEN 1 ELSE 1 END')
        .expectError('(1, 2, 3)');
  });

  test('in CASE - base', () {
    engine
        .analyze('SELECT CASE (1, 2, 3) WHEN 1 THEN 1 ELSE 1 END')
        .expectError('(1, 2, 3)');
  });

  group('does not generate error for valid usage', () {
    test('in comparison', () {
      engine.analyze('SELECT (1, 2, 3) < (?, ?, ?);').expectNoError();
    });

    test('in IN expression (lhs)', () {
      engine.analyze('SELECT (1, 2, 3) IN (VALUES(0, 1, 2))').expectNoError();
    });

    test('in IN expression (rhs)', () {
      engine.analyze('SELECT ? IN (1, 2, 3)').expectNoError();
    });

    test('in BETWEEN expression', () {
      engine.analyze('SELECT (1, 2) BETWEEN (3, 4) AND (5, 6)').expectNoError();
    });

    test('in CASE expression', () {
      engine
          .analyze('SELECT CASE (1, 2) WHEN (1, 2) THEN 1 ELSE 0 END')
          .expectNoError();
    });
  });
}

extension on AnalysisContext {
  void expectError(String lexeme) {
    expect(
      errors,
      [
        isA<AnalysisError>()
            .having((e) => e.type, 'type', AnalysisErrorType.rowValueMisuse)
            .having((e) => e.span.text, 'span.text', lexeme),
      ],
    );
  }

  void expectNoError() {
    expect(errors, isEmpty);
  }
}
