import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  final i1 = Expression<int>.custom('i1', precedence: Precedence.primary);
  final i2 = Expression<int>.custom('i2', precedence: Precedence.primary);
  final b1 = Expression<BigInt>.custom('b1', precedence: Precedence.primary);
  final b2 = Expression<BigInt>.custom('b2', precedence: Precedence.primary);
  final s1 = Expression<String>.custom('s1', precedence: Precedence.primary);
  final s2 = Expression<String>.custom('s2', precedence: Precedence.primary);

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

  test('BigInt arithmetic test', () {
    expect(b1 + b2 * b1, generates('b1 + b2 * b1'));
    expect(b1 + b2 * b1, generates('b1 + b2 * b1'));
    expect((b1 + b2) * b1, generates('(b1 + b2) * b1'));
    expect(b1 - b2, generates('b1 - b2'));
    expect(b1 - -b2, generates('b1 - -b2'));
    expect(b1 / b2, generates('b1 / b2'));

    expectEquals(i1 + i2, i1 + i2);
    expectNotEquals(i1 + i2, i2 + i1);
  });

  test('string concatenation', () {
    expect(s1 + s2, generates('s1 || s2'));
  });

  test('absolute values', () {
    expect(i2.abs(), generates('abs(i2)'));
  });

  test('with variables', () {
    expect(
      const Variable(0) - (i1 - Variable(10)),
      generates('?1 - (i1 - ?2)', [0, 10]),
    );
    expect(
      (const Variable(0) - i1) - Variable(10),
      generates('(?1 - i1) - ?2', [0, 10]),
    );
  });
}
