import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  final a = Expression<bool>.custom('a', precedence: Precedence.primary);
  final b = Expression<bool>.custom('b', precedence: Precedence.primary);
  final c = Expression<bool>.custom('c', precedence: Precedence.primary);
  final d = Expression<bool>.custom('d', precedence: Precedence.primary);

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
