import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const foo = CustomExpression<int>('foo', precedence: Precedence.primary);
  const b1 = CustomExpression<BigInt>('b1', precedence: Precedence.primary);
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
        countAll(filter: b1.isBiggerOrEqualValue(BigInt.from(3))),
        generates('COUNT(*) FILTER (WHERE b1 >= ?)', [BigInt.from(3)]),
      );
      expect(
        countAll(filter: s1.equals('STRING_VALUE')),
        generates('COUNT(*) FILTER (WHERE s1 = ?)', ['STRING_VALUE']),
      );
    });

    test('single', () {
      expect(foo.count(), generates('COUNT(foo)'));
      expect(b1.count(), generates('COUNT(b1)'));
      expect(s1.count(), generates('COUNT(s1)'));
    });

    test('single - distinct', () {
      expect(foo.count(distinct: true), generates('COUNT(DISTINCT foo)'));
      expect(b1.count(distinct: true), generates('COUNT(DISTINCT b1)'));
      expect(s1.count(distinct: true), generates('COUNT(DISTINCT s1)'));
    });

    test('single - filter', () {
      expect(
        foo.count(filter: foo.isBiggerOrEqualValue(3)),
        generates('COUNT(foo) FILTER (WHERE foo >= ?)', [3]),
      );
      expect(
        b1.count(filter: b1.isBiggerOrEqualValue(BigInt.from(3))),
        generates('COUNT(b1) FILTER (WHERE b1 >= ?)', [BigInt.from(3)]),
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
        b1.count(
            distinct: true, filter: b1.isBiggerOrEqualValue(BigInt.from(3))),
        generates(
            'COUNT(DISTINCT b1) FILTER (WHERE b1 >= ?)', [BigInt.from(3)]),
      );
      expect(
        s1.count(distinct: true, filter: s1.equals('STRING_VALUE')),
        generates('COUNT(DISTINCT s1) FILTER (WHERE s1 = ?)', ['STRING_VALUE']),
      );
    });
  });

  test('avg', () {
    expect(foo.avg(), generates('AVG(foo)'));
    expect(b1.avg(), generates('AVG(b1)'));

    expect(foo.avg(filter: foo.isBiggerOrEqualValue(3)),
        generates('AVG(foo) FILTER (WHERE foo >= ?)', [3]));
    expect(b1.avg(filter: b1.isBiggerOrEqualValue(BigInt.from(3))),
        generates('AVG(b1) FILTER (WHERE b1 >= ?)', [BigInt.from(3)]));
  });

  test('max', () {
    expect(foo.max(), generates('MAX(foo)'));
    expect(b1.max(), generates('MAX(b1)'));
    expect(s1.max(), generates('MAX(s1)'));
  });

  test('min', () {
    expect(foo.min(), generates('MIN(foo)'));
    expect(b1.min(), generates('MIN(b1)'));
    expect(s1.min(), generates('MIN(s1)'));
  });

  test('sum', () {
    expect(foo.sum(), generates('SUM(foo)'));
    expect(b1.sum(), generates('SUM(b1)'));
  });

  test('total', () {
    expect(foo.total(), generates('TOTAL(foo)'));
    expect(b1.total(), generates('TOTAL(b1)'));
  });

  group('group_concat', () {
    test('with the default separator', () {
      expect(foo.groupConcat(), generates('GROUP_CONCAT(foo)'));
      expect(b1.groupConcat(), generates('GROUP_CONCAT(b1)'));
      expect(s1.groupConcat(), generates('GROUP_CONCAT(s1)'));

      expect(foo.groupConcat(separator: ','), generates('GROUP_CONCAT(foo)'));
      expect(b1.groupConcat(separator: ','), generates('GROUP_CONCAT(b1)'));
      expect(s1.groupConcat(separator: ','), generates('GROUP_CONCAT(s1)'));
    });

    test('with a custom separator', () {
      expect(foo.groupConcat(separator: ' and '),
          generates('GROUP_CONCAT(foo, ?)', [' and ']));
      expect(b1.groupConcat(separator: ' and '),
          generates('GROUP_CONCAT(b1, ?)', [' and ']));
      expect(s1.groupConcat(separator: ' and '),
          generates('GROUP_CONCAT(s1, ?)', [' and ']));
    });

    test('with a filter', () {
      expect(foo.groupConcat(filter: foo.isSmallerThan(const Variable(3))),
          generates('GROUP_CONCAT(foo) FILTER (WHERE foo < ?)', [3]));
      expect(
          b1.groupConcat(filter: b1.isSmallerThan(Variable(BigInt.from(3)))),
          generates(
              'GROUP_CONCAT(b1) FILTER (WHERE b1 < ?)', [BigInt.from(3)]));
      expect(
          s1.groupConcat(filter: s1.isSmallerThan(Variable('STRING_VALUE'))),
          generates(
              'GROUP_CONCAT(s1) FILTER (WHERE s1 < ?)', ['STRING_VALUE']));
    });

    test('with distinct', () {
      expect(foo.groupConcat(distinct: true),
          generates('GROUP_CONCAT(DISTINCT foo)', isEmpty));
      expect(b1.groupConcat(distinct: true),
          generates('GROUP_CONCAT(DISTINCT b1)', isEmpty));
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
        b1.groupConcat(
          distinct: true,
          filter: b1.isSmallerThan(Variable(BigInt.from(3))),
        ),
        generates(
          'GROUP_CONCAT(DISTINCT b1) FILTER (WHERE b1 < ?)',
          [BigInt.from(3)],
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
      expect(() => b1.groupConcat(distinct: true, separator: ' and '),
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
        () => b1.groupConcat(
          distinct: true,
          separator: ' and ',
          filter: b1.isSmallerThan(Variable(BigInt.from(3))),
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
