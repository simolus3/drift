import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';
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

    // SQLite accepts all of these on row values (checked against the real
    // library): https://www.sqlite.org/rowvalue.html#comparisons
    for (final operator in [
      '=',
      '==',
      '<>',
      '!=',
      '<',
      '<=',
      '>',
      '>=',
      'IS',
      'IS NOT',
      'IS DISTINCT FROM',
      'IS NOT DISTINCT FROM',
    ]) {
      test('in comparison with $operator', () {
        SqlEngine(EngineOptions(version: SqliteVersion.current))
            .analyze(
              'SELECT (1, 2) $operator (?, ?), (SELECT 1, 2) $operator (1, 2)',
            )
            .expectNoError();
      });
    }

    for (final operator in ['!=', 'IS', 'IS NOT']) {
      test('tuple against a subquery with $operator', () {
        engine
            .analyze(
              'SELECT (1, 2) $operator (SELECT 1, 2), '
              '(SELECT 1, 2) $operator (1, 2)',
            )
            .expectNoError();
      });
    }

    test('subquery of real columns against a tuple or a subquery', () {
      final withTable = SqlEngine(
        EngineOptions(version: SqliteVersion.current),
      )..registerTableFromSql('CREATE TABLE t (a INTEGER, b INTEGER, c TEXT);');
      for (final sql in [
        'SELECT (1, 2) != (SELECT a, b FROM t)',
        'SELECT (SELECT a, b FROM t) IS (1, 2)',
        'SELECT (SELECT a, b FROM t) IS NOT (SELECT 1, 2)',
        'SELECT (SELECT a, b FROM t) != (SELECT b, c FROM t)',
        'SELECT (SELECT 1, 2) IS (SELECT 3, 4)',
        'SELECT (1, 2) != (SELECT * FROM (SELECT a, b FROM t))',
      ]) {
        withTable.analyze(sql).expectNoError();
      }
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

  group('in operators that do not compare', () {
    void expectMisuse(String sql, int count) {
      final errors = SqlEngine(
        EngineOptions(version: SqliteVersion.current),
      ).analyze(sql).errors;
      expect(errors, hasLength(count));
      expect(
        errors.map((e) => e.type),
        everyElement(AnalysisErrorType.rowValueMisuse),
      );
    }

    for (final operator in ['LIKE', 'GLOB', 'AND', 'OR', '+', '||', '&']) {
      test(operator, () => expectMisuse('SELECT (1, 2) $operator (3, 4)', 2));
    }

    for (final sql in [
      'SELECT (1, 2) IS NULL',
      'SELECT (1, 2) IS NOT NULL',
      'SELECT (1, 2) IS 1',
      'SELECT (1, 2) ISNULL',
      'SELECT (1, 2) NOTNULL',
    ]) {
      test(sql, () => expectMisuse(sql, 1));
    }

    // A row value compared with something that is not a row value.
    for (final (sql, count) in [
      ('SELECT (1, 2) != 1', 1),
      ('SELECT 1 != (1, 2)', 1),
      ('SELECT (1, 2) != NULL', 1),
      ('SELECT (1, 2) = 1', 1),
      ('SELECT 1 < (1, 2)', 1),
    ]) {
      test(sql, () => expectMisuse(sql, count));
    }
  });

  group('row values of different sizes', () {
    void expectSizeMismatch(String sql, String message, {int count = 1}) {
      final errors = SqlEngine(
        EngineOptions(version: SqliteVersion.current),
      ).analyze(sql).errors;
      expect(errors, hasLength(count));
      for (final error in errors) {
        expect(error.type, AnalysisErrorType.rowValueSizeMismatch);
        expect(error.message, message);
      }
    }

    // SQLite reports "row value misused" for every one of these.
    for (final operator in [
      '=',
      '==',
      '<>',
      '!=',
      '<',
      '<=',
      '>',
      '>=',
      'IS',
      'IS NOT',
      'IS DISTINCT FROM',
      'IS NOT DISTINCT FROM',
    ]) {
      test('tuples with $operator', () {
        expectSizeMismatch(
          'SELECT (1, 2) $operator (1, 2, 3)',
          'Row values must have the same number of columns (2 and 3)',
        );
      });

      test('tuple and subquery with $operator', () {
        expectSizeMismatch(
          'SELECT (1, 2) $operator (SELECT 1)',
          'Row values must have the same number of columns (2 and 1)',
        );
        expectSizeMismatch(
          'SELECT (SELECT 1, 2, 3) $operator (1, 2)',
          'Row values must have the same number of columns (3 and 2)',
        );
      });
    }

    test('are not reported when the size of a subquery is unknown', () {
      final errors = SqlEngine(
        EngineOptions(version: SqliteVersion.current),
      ).analyze('SELECT (1, 2) != (SELECT * FROM unknown_table)').errors;
      expect(
        errors.map((e) => e.type),
        isNot(contains(AnalysisErrorType.rowValueSizeMismatch)),
      );
      expect(
        errors.map((e) => e.type),
        isNot(contains(AnalysisErrorType.rowValueMisuse)),
      );
    });
  });

  group('in expressions', () {
    test('when tuple is expected', () {
      engine
          .analyze('SELECT (1, 2) IN ((4, 5), 6)')
          .expectError(
            '6',
            type: AnalysisErrorType.other,
            message: contains('Expected 2 columns in this entry, got 1'),
          );
    });

    test('when tuple is not expected', () {
      engine
          .analyze('SELECT 1 IN ((4, 5), 6)')
          .expectError(
            '(4, 5)',
            type: AnalysisErrorType.other,
            message: contains('Expected 1 columns in this entry, got 2'),
          );
    });

    test('for table reference', () {
      engine
          .analyze('WITH names AS (VALUES(1, 2, 3)) SELECT (1, 2) IN names')
          .expectError(
            'names',
            type: AnalysisErrorType.other,
            message: contains('must have 2 columns (it has 3)'),
          );
    });

    test('for table-valued function', () {
      engine
          .analyze("SELECT (1, 2) IN json_each('{}')")
          .expectError(
            "json_each('{}')",
            type: AnalysisErrorType.other,
            message: contains('this table must have 2 columns (it has 8)'),
          );
    });
  });
}
