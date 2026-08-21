import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  final expression = Expression<int>.custom(
    'col',
    precedence: Precedence.primary,
  );

  final comparisons = {
    expression.isLessThan: '<',
    expression.isLessOrEqual: '<=',
    expression.isGreaterOrEqual: '>=',
    expression.isGreaterThan: '>',
  };

  final comparisonsVal = {
    expression.isLessThanValue: '<',
    expression.isLessOrEqualValue: '<=',
    expression.isGreaterOrEqualValue: '>=',
    expression.isGreaterThanValue: '>',
  };

  group('can compare with other expressions', () {
    final compare = Expression<int>.custom(
      'compare',
      precedence: Precedence.primary,
    );

    comparisons.forEach((fn, value) {
      test('for operator $value', () {
        expect(fn(compare), generates('col $value compare'));
        expectEquals(fn(compare), fn(compare));
      });
    });
  });

  group('can compare with values', () {
    comparisonsVal.forEach((fn, value) {
      test('for operator $value', () {
        expect(fn(12), generates('col $value ?1', [12]));
      });
    });
  });

  group('between', () {
    test('other expressions', () {
      final low = Expression<int>.custom('low', precedence: Precedence.primary);
      final high = Expression<int>.custom(
        'high',
        precedence: Precedence.primary,
      );

      expect(
        expression.isBetween(low, high),
        generates('col BETWEEN low AND high'),
      );
    });

    test('values', () {
      expect(
        expression.isBetweenValues(3, 15),
        generates('col BETWEEN ?1 AND ?2', [3, 15]),
      );
    });
  });

  group('special case for date time values as text', () {
    final a = Expression<DateTime>.custom('a', precedence: Precedence.primary);
    final b = Expression<DateTime>.custom('b', precedence: Precedence.primary);
    final c = Expression<DateTime>.custom('c', precedence: Precedence.primary);

    test('disabled for datetimes as timestamps', () {
      const asTimestamps = SqliteDialect.withOptions(
        options: SqliteOptions(storeDateTimesAsText: false),
      );

      expect(
        a.isLessThan(b),
        generatesWithDialect('a < b', dialect: asTimestamps),
      );
      expect(
        a.isGreaterOrEqual(b),
        generatesWithDialect('a >= b', dialect: asTimestamps),
      );
      expect(
        a.isBetween(b, c),
        generatesWithDialect('a BETWEEN b AND c', dialect: asTimestamps),
      );
    });

    test('enabled for datetimes as timestamps', () {
      expect(a.isLessThan(b), generates('julianday(a) < julianday(b)'));
      expect(a.isGreaterOrEqual(b), generates('julianday(a) >= julianday(b)'));
      expect(
        a.isBetween(b, c),
        generates('julianday(a) BETWEEN julianday(b) AND julianday(c)'),
      );
    });
  });
}
