import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const x = Expression<String>.custom(CustomComponent('x'));
  const y = Expression<int>.custom(CustomComponent('y'));

  group('CASE WHEN with base expression', () {
    test('WHEN without ELSE', () {
      expect(
        x.caseMatch<int>(when: {
          const Literal('a'): const Literal(1),
          const Literal('b'): const Literal(2),
        }),
        generates("CASE x WHEN 'a' THEN 1 WHEN 'b' THEN 2 END"),
      );
    });

    test('WHEN with ELSE', () {
      expect(
        x.caseMatch<int>(
          when: {
            const Literal('a'): const Literal(1),
          },
          orElse: y,
        ),
        generates("CASE x WHEN 'a' THEN 1 ELSE y END"),
      );
    });

    test('does not allow empty WHEN map', () {
      expect(() => x.caseMatch<Object>(when: const {}),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('CASE WHEN without base expression', () {
    test('WHEN without ELSE', () {
      expect(
        CaseWhenExpression.conditional<int>(cases: [
          (
            when: Expression.custom(CustomComponent("'id' IS 1")),
            then: Literal(1)
          ),
          (
            when: Expression.custom(CustomComponent("'id' IS 2")),
            then: Literal(2)
          ),
        ]),
        generates("CASE WHEN 'id' IS 1 THEN 1 WHEN 'id' IS 2 THEN 2 END"),
      );
    });

    test('WHEN with ELSE', () {
      expect(
        CaseWhenExpression.conditional<int>(
          cases: const [
            (
              when: Expression.custom(CustomComponent("'id' IS 1")),
              then: Literal(1),
            )
          ],
          orElse: y,
        ),
        generates("CASE WHEN 'id' IS 1 THEN 1 ELSE y END"),
      );
    });

    test('does not allow empty WHEN map', () {
      expect(() => CaseWhenExpression.conditional<int>(cases: const []),
          throwsA(isA<ArgumentError>()));
    });
  });

  test('IIF', () {
    expect(
      x.iif(Expression<bool>.custom(CustomComponent('1 = 1')),
          const Literal('y')),
      generates("IIF(1 = 1,x,'y')"),
    );
  });
}
