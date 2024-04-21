import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late SqlEngine engine;
  setUp(() {
    // enable json1 extension
    engine = SqlEngine(EngineOptions(version: SqliteVersion.v3_38));
  });

  test('when using row value in select', () {
    engine
        .analyze('SELECT (1, 2, 3)')
        .expectError('(1, 2, 3)', type: AnalysisErrorType.rowValueMisuse);
  });

  test('in BETWEEN expression', () {
    engine
        .analyze('SELECT 1 BETWEEN (1, 2, 3) AND 3')
        .expectError('(1, 2, 3)', type: AnalysisErrorType.rowValueMisuse);
  });

  test('in CASE - value', () {
    engine
        .analyze('SELECT CASE 1 WHEN 1 THEN (1, 2, 3) ELSE 1 END')
        .expectError('(1, 2, 3)', type: AnalysisErrorType.rowValueMisuse);
  });

  test('in CASE - when', () {
    engine
        .analyze('SELECT CASE 1 WHEN (1, 2, 3) THEN 1 ELSE 1 END')
        .expectError('(1, 2, 3)', type: AnalysisErrorType.rowValueMisuse);
  });

  test('in CASE - base', () {
    engine
        .analyze('SELECT CASE (1, 2, 3) WHEN 1 THEN 1 ELSE 1 END')
        .expectError('(1, 2, 3)', type: AnalysisErrorType.rowValueMisuse);
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

  group('in expressions', () {
    test('when tuple is expected', () {
      engine.analyze('SELECT (1, 2) IN ((4, 5), 6)').expectError('6',
          type: AnalysisErrorType.other,
          message: contains('Expected 2 columns in this entry, got 1'));
    });

    test('when tuple is not expected', () {
      engine.analyze('SELECT 1 IN ((4, 5), 6)').expectError('(4, 5)',
          type: AnalysisErrorType.other,
          message: contains('Expected 1 columns in this entry, got 2'));
    });

    test('for table reference', () {
      engine
          .analyze('WITH names AS (VALUES(1, 2, 3)) SELECT (1, 2) IN names')
          .expectError('names',
              type: AnalysisErrorType.other,
              message: contains('must have 2 columns (it has 3)'));
    });

    test('for table-valued function', () {
      engine.analyze("SELECT (1, 2) IN json_each('{}')").expectError(
          "json_each('{}')",
          type: AnalysisErrorType.other,
          message: contains('this table must have 2 columns (it has 8)'));
    });
  });
}
