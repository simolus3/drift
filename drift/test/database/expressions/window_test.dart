import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const foo = CustomExpression<int>('foo', precedence: Precedence.primary);
  const x = CustomExpression<String>('x');
  const y = CustomExpression<int>('y');

  group('WINDOW FUNCTION', () {
    test('with single Order By', () {
      expect(
        WindowFunctionExpression<int>(
          foo.sum(),
          orderBy: [OrderingTerm.asc(foo)],
        ),
        generates(
            "SUM(foo) OVER (ORDER BY foo ASC RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)"),
      );
    });

    test('with multiple Order By', () {
      expect(
        WindowFunctionExpression<int>(
          foo.sum(),
          orderBy: [OrderingTerm.asc(foo), OrderingTerm.desc(x)],
        ),
        generates(
            "SUM(foo) OVER (ORDER BY foo ASC, x DESC RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)"),
      );
    });

    test('with Partition By', () {
      expect(
        WindowFunctionExpression<double>(
          foo.avg(),
          orderBy: [OrderingTerm.desc(foo)],
          partitionBy: [x, y],
        ),
        generates(
            "AVG(foo) OVER (PARTITION BY x, y ORDER BY foo DESC RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)"),
      );
    });

    test('with Filter', () {
      expect(
        WindowFunctionExpression(
          countAll(filter: foo.isBiggerOrEqualValue(3)),
          orderBy: [OrderingTerm.desc(foo)],
          partitionBy: [x, y],
        ),
        generates(
            "COUNT(*) FILTER (WHERE foo >= ?) OVER (PARTITION BY x, y ORDER BY foo DESC RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)",
            [3]),
      );
    });

    test('does not allow empty Order By', () {
      expect(
          () => WindowFunctionExpression<double>(
                foo.avg(),
                orderBy: [],
              ),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('WINDOW FUNCTION Frame Spec', () {
    test('between unbounded preceding and current row', () {
      expect(
        FrameBoundary.rows(),
        generates("ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW"),
      );
      expect(
        FrameBoundary.groups(),
        generates("GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW"),
      );
      expect(
        FrameBoundary.range(),
        generates("RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW"),
      );
    });

    test('between unbounded preceding and unbounded following', () {
      expect(
        FrameBoundary.rows(start: null, end: null),
        generates("ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING"),
      );
      expect(
        FrameBoundary.groups(start: null, end: null),
        generates("GROUPS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING"),
      );
      expect(
        FrameBoundary.range(start: null, end: null),
        generates("RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING"),
      );
    });

    test('between expr preceding and/or expr following', () {
      expect(
        FrameBoundary.range(
          start: -2,
          end: 0,
        ),
        generates("RANGE BETWEEN 2 PRECEDING AND CURRENT ROW"),
      );
      expect(
        FrameBoundary.rows(
          start: -4,
          end: 6,
        ),
        generates("ROWS BETWEEN 4 PRECEDING AND 6 FOLLOWING"),
      );
      expect(
        FrameBoundary.groups(
          start: null,
          end: -4,
        ),
        generates("GROUPS BETWEEN UNBOUNDED PRECEDING AND 4 PRECEDING"),
      );
      expect(
        FrameBoundary.rows(
          start: 0,
          end: null,
        ),
        generates("ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING"),
      );
      expect(
        FrameBoundary.rows(
          start: 6,
          end: null,
        ),
        generates("ROWS BETWEEN 6 FOLLOWING AND UNBOUNDED FOLLOWING"),
      );
      expect(
        FrameBoundary.range(
          start: -6.78,
          end: 57,
        ),
        generates("RANGE BETWEEN 6.78 PRECEDING AND 57 FOLLOWING"),
      );
    });

    test('allows reverse boundary of same type', () {
      expect(
        FrameBoundary.range(
          start: -6,
          end: -1,
        ),
        generates("RANGE BETWEEN 6 PRECEDING AND 1 PRECEDING"),
      );

      expect(
        FrameBoundary.groups(
          start: 4,
          end: 1,
        ),
        generates("GROUPS BETWEEN 4 FOLLOWING AND 1 FOLLOWING"),
      );
    });

    test(
        'does not allow reverse boundary of different type (start with FOLLOWING and end with PRECEDING or CURRENT ROW)',
        () {
      expect(
          () => FrameBoundary.range(
                start: 6,
                end: 0,
              ),
          throwsA(isA<AssertionError>()));
      expect(
          () => FrameBoundary.range(
                start: 6,
                end: -3,
              ),
          throwsA(isA<AssertionError>()));
    });

    test('Exclude boundary', () {
      expect(
        FrameBoundary.range(
          exclude: FrameExclude.noOthers,
        ),
        generates(
            "RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS"),
      );
      expect(
        FrameBoundary.rows(
          exclude: FrameExclude.currentRow,
        ),
        generates(
            "ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE CURRENT ROW"),
      );
      expect(
        FrameBoundary.groups(
          exclude: FrameExclude.group,
        ),
        generates(
            "GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE GROUP"),
      );
      expect(
        FrameBoundary.range(
          exclude: FrameExclude.ties,
        ),
        generates(
            "RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE TIES"),
      );
    });
  });
}
