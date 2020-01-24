import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/utils/expect_generated.dart';

void main() {
  final foo = GeneratedIntColumn('foo', 'bar', false);

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
}
