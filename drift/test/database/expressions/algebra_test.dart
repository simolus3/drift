import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const i1 = CustomExpression<int>('i1', precedence: Precedence.primary);
  const i2 = CustomExpression<int>('i2', precedence: Precedence.primary);
  const s1 = CustomExpression<String>('s1', precedence: Precedence.primary);
  const s2 = CustomExpression<String>('s2', precedence: Precedence.primary);

  test('arithmetic test', () {
    expect(i1 + i2 * i1, generates('i1 + i2 * i1'));
    expect(i1 + i2 * i1, generates('i1 + i2 * i1'));
    expect((i1 + i2) * i1, generates('(i1 + i2) * i1'));
    expect(i1 - i2, generates('i1 - i2'));
    expect(i1 - -i2, generates('i1 - -i2'));
    expect(i1 / i2, generates('i1 / i2'));

    expectEquals(i1 + i2, i1 + i2);
    expectNotEquals(i1 + i2, i2 + i1);
  });

  test('string concatenation', () {
    expect(s1 + s2, generates('s1 || s2'));
  });

  test('absolute values', () {
    expect(i2.abs(), generates('abs(i2)'));
  });
}
