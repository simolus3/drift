import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const foo = CustomExpression<int>('foo', precedence: Precedence.primary);

  group('count', () {
    test('all', () {
      expect(countAll(), generates('COUNT(*)'));
    });

    test('all - filter', () {
      expect(
        countAll(filter: foo.isBiggerOrEqualValue(3)),
        generates('COUNT(*) FILTER (WHERE foo >= ?)', [3]),
      );
    });

    test('single', () {
      expect(foo.count(), generates('COUNT(foo)'));
    });

    test('single - distinct', () {
      expect(foo.count(distinct: true), generates('COUNT(DISTINCT foo)'));
    });

    test('single - filter', () {
      expect(
        foo.count(filter: foo.isBiggerOrEqualValue(3)),
        generates('COUNT(foo) FILTER (WHERE foo >= ?)', [3]),
      );
    });

    test('single - distinct and filter', () {
      expect(
        foo.count(distinct: true, filter: foo.isBiggerOrEqualValue(3)),
        generates('COUNT(DISTINCT foo) FILTER (WHERE foo >= ?)', [3]),
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
  });

  test('min', () {
    expect(foo.min(), generates('MIN(foo)'));
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
      expect(foo.groupConcat(separator: ','), generates('GROUP_CONCAT(foo)'));
    });

    test('with a custom separator', () {
      expect(foo.groupConcat(separator: ' and '),
          generates('GROUP_CONCAT(foo, ?)', [' and ']));
    });

    test('with a filter', () {
      expect(foo.groupConcat(filter: foo.isSmallerThan(const Variable(3))),
          generates('GROUP_CONCAT(foo) FILTER (WHERE foo < ?)', [3]));
    });

    test('with distinct', () {
      expect(foo.groupConcat(distinct: true),
          generates('GROUP_CONCAT(DISTINCT foo)', isEmpty));

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
    });

    test('does not allow distinct with a custom separator', () {
      expect(() => foo.groupConcat(distinct: true, separator: ' and '),
          throwsArgumentError);

      expect(
        () => foo.groupConcat(
          distinct: true,
          separator: ' and ',
          filter: foo.isSmallerThan(const Variable(3)),
        ),
        throwsArgumentError,
      );
    });
  });
}
