import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const a = CustomExpression<bool>('a', precedence: Precedence.primary);
  const b = CustomExpression<bool>('b', precedence: Precedence.primary);

  test('boolean expressions via operators', () {
    expect(a | b, generates('a OR b'));
    expect(a & b, generates('a AND b'));
    expect(a.not(), generates('NOT a'));

    expectEquals(a & b, a & b);
    expectNotEquals(a | b, b | a);
  });
}
