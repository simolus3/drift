import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const a = Expression<bool>.custom(CustomComponent('a'),
      precedence: Precedence.primary);
  const b = Expression<bool>.custom(CustomComponent('b'),
      precedence: Precedence.primary);
  const c = Expression<bool>.custom(CustomComponent('c'),
      precedence: Precedence.primary);
  const d = Expression<bool>.custom(CustomComponent('d'),
      precedence: Precedence.primary);

  test('boolean expressions via operators', () {
    expect(a | b, generates('a OR b'));
    expect(a & b, generates('a AND b'));
    expect(a.not(), generates('NOT a'));

    expectEquals(a & b, a & b);
    expectNotEquals(a | b, b | a);
  });

  test('respects precedence', () {
    expect(a | b & c, generates('a OR b AND c'));
    expect(a | (b & c), generates('a OR b AND c'));
    expect((a | b) & c, generates('(a OR b) AND c'));

    expect(
      Expression.and([
        a,
        Expression.or([
          b,
          Expression.and([c, d]),
        ]),
      ]),
      generates('a AND (b OR c AND d)'),
    );
  });
}
