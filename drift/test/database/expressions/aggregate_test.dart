import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const foo = CustomExpression<int>('foo', precedence: Precedence.primary);
  const s1 = CustomExpression<String>('s1', precedence: Precedence.primary);

  group('count', () {
    test('all', () {
      expect(countAll(), generates('COUNT(*)'));
    });

    test('all - filter', () {
      expect(
        countAll(filter: foo.isBiggerOrEqualValue(3)),
        generates('COUNT(*) FILTER (WHERE foo >= ?)', [3]),
      );
      expect(
        countAll(filter: s1.equals('STRING_VALUE')),
        generates('COUNT(*) FILTER (WHERE s1 = ?)', ['STRING_VALUE']),
      );
    });

    test('single', () {
      expect(foo.count(), generates('COUNT(foo)'));
      expect(s1.count(), generates('COUNT(s1)'));
    });

    test('single - distinct', () {
      expect(foo.count(distinct: true), generates('COUNT(DISTINCT foo)'));
      expect(s1.count(distinct: true), generates('COUNT(DISTINCT s1)'));
    });

    test('single - filter', () {
      expect(
        foo.count(filter: foo.isBiggerOrEqualValue(3)),
        generates('COUNT(foo) FILTER (WHERE foo >= ?)', [3]),
      );
      expect(
        s1.count(filter: s1.equals('STRING_VALUE')),
        generates('COUNT(s1) FILTER (WHERE s1 = ?)', ['STRING_VALUE']),
      );
    });

    test('single - distinct and filter', () {
      expect(
        foo.count(distinct: true, filter: foo.isBiggerOrEqualValue(3)),
        generates('COUNT(DISTINCT foo) FILTER (WHERE foo >= ?)', [3]),
      );
      expect(
        s1.count(distinct: true, filter: s1.equals('STRING_VALUE')),
        generates('COUNT(DISTINCT s1) FILTER (WHERE s1 = ?)', ['STRING_VALUE']),
      );
    });
  });

  test('avg', () {
    expect(foo.avg(), generates('AVG(foo)'));
    expect(foo.avg(filter: foo.isBiggerOrEqualValue(3)),
        generates('AVG(foo) FILTER (WHERE foo >= ?)', [3]));
  });

  test('max', () {
    expect(foo.max(), generates('MAX(foo)'));
    expect(s1.max(), generates('MAX(s1)'));
  });

  test('min', () {
    expect(foo.min(), generates('MIN(foo)'));
    expect(s1.min(), generates('MIN(s1)'));
  });

  test('sum', () {
    expect(foo.sum(), generates('SUM(foo)'));
  });

  test('total', () {
    expect(foo.total(), generates('TOTAL(foo)'));
  });

  group('group_concat', () {
    test('with the default separator', () {
      expect(foo.groupConcat(), generates('GROUP_CONCAT(foo)'));
      expect(s1.groupConcat(), generates('GROUP_CONCAT(s1)'));

      expect(foo.groupConcat(separator: ','), generates('GROUP_CONCAT(foo)'));
      expect(s1.groupConcat(separator: ','), generates('GROUP_CONCAT(s1)'));
    });

    test('with a custom separator', () {
      expect(foo.groupConcat(separator: ' and '),
          generates('GROUP_CONCAT(foo, ?)', [' and ']));
      expect(s1.groupConcat(separator: ' and '),
          generates('GROUP_CONCAT(s1, ?)', [' and ']));
    });

    test('with a filter', () {
      expect(foo.groupConcat(filter: foo.isSmallerThan(const Variable(3))),
          generates('GROUP_CONCAT(foo) FILTER (WHERE foo < ?)', [3]));
      expect(
          s1.groupConcat(filter: s1.isSmallerThan(Variable('STRING_VALUE'))),
          generates(
              'GROUP_CONCAT(s1) FILTER (WHERE s1 < ?)', ['STRING_VALUE']));
    });

    test('with distinct', () {
      expect(foo.groupConcat(distinct: true),
          generates('GROUP_CONCAT(DISTINCT foo)', isEmpty));
      expect(s1.groupConcat(distinct: true),
          generates('GROUP_CONCAT(DISTINCT s1)', isEmpty));

      expect(
        foo.groupConcat(
          distinct: true,
          filter: foo.isSmallerThan(const Variable(3)),
        ),
        generates(
          'GROUP_CONCAT(DISTINCT foo) FILTER (WHERE foo < ?)',
          [3],
        ),
      );
      expect(
        s1.groupConcat(
          distinct: true,
          filter: s1.isSmallerThan(Variable('STRING_VALUE')),
        ),
        generates(
          'GROUP_CONCAT(DISTINCT s1) FILTER (WHERE s1 < ?)',
          ['STRING_VALUE'],
        ),
      );
    });

    test('does not allow distinct with a custom separator', () {
      expect(() => foo.groupConcat(distinct: true, separator: ' and '),
          throwsArgumentError);
      expect(() => s1.groupConcat(distinct: true, separator: ' and '),
          throwsArgumentError);

      expect(
        () => foo.groupConcat(
          distinct: true,
          separator: ' and ',
          filter: foo.isSmallerThan(const Variable(3)),
        ),
        throwsArgumentError,
      );
      expect(
        () => s1.groupConcat(
          distinct: true,
          separator: ' and ',
          filter: s1.isSmallerThan(Variable('STRING_VALUE')),
        ),
        throwsArgumentError,
      );
    });
  });
}
