import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const expression = Expression<int>.customComponent(CustomComponent('col'),
      precedence: Precedence.primary);

  final comparisons = {
    expression.isLessThan: '<',
    expression.isLessOrEqual: '<=',
    expression.isGreaterOrEqual: '>=',
    expression.isGreaterThan: '>'
  };

  final comparisonsVal = {
    expression.isLessThanValue: '<',
    expression.isLessOrEqualValue: '<=',
    expression.isGreaterOrEqualValue: '>=',
    expression.isGreaterThanValue: '>'
  };

  group('can compare with other expressions', () {
    const compare = Expression<int>.customComponent(CustomComponent('compare'),
        precedence: Precedence.primary);

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
      const low = Expression<int>.customComponent(CustomComponent('low'),
          precedence: Precedence.primary);
      const high = Expression<int>.customComponent(CustomComponent('high'),
          precedence: Precedence.primary);

      expect(expression.isBetween(low, high),
          generates('col BETWEEN low AND high'));
    });

    test('values', () {
      expect(expression.isBetweenValues(3, 15),
          generates('col BETWEEN ?1 AND ?2', [3, 15]));
    });
  });

  group('special case for date time values as text', () {
    const a = Expression<DateTime>.customComponent(CustomComponent('a'),
        precedence: Precedence.primary);
    const b = Expression<DateTime>.customComponent(CustomComponent('b'),
        precedence: Precedence.primary);
    const c = Expression<DateTime>.customComponent(CustomComponent('c'),
        precedence: Precedence.primary);

    test('disabled for datetimes as timestamps', () {
      const dialect = SqliteDialect(
          options: SqliteOptions(
        storeDateTimesAsText: false,
      ));

      expect(a.isLessThan(b), generatesWithOptions('a < b', dialect: dialect));
      expect(a.isGreaterOrEqual(b),
          generatesWithOptions('a >= b', dialect: dialect));
      expect(a.isBetween(b, c),
          generatesWithOptions('a BETWEEN b AND c', dialect: dialect));
    });

    test('enabled for datetimes as timestamps', () {
      expect(a.isLessThan(b), generates('julianday(a) < julianday(b)'));
      expect(a.isGreaterOrEqual(b), generates('julianday(a) >= julianday(b)'));
      expect(a.isBetween(b, c),
          generates('julianday(a) BETWEEN julianday(b) AND julianday(c)'));
    });
  });
}
