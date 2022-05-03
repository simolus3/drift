import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  final i1 = Expression<int>.sql('i1', precedence: Precedence.primary);
  final i2 = Expression<int>.sql('i2', precedence: Precedence.primary);

  test('arithmetic test', () {
    expect(i1 + i2 * i1, generates('i1 + i2 * i1'));
    expect(i1 + i2 * i1, generates('i1 + i2 * i1'));
    expect((i1 + i2) * i1, generates('(i1 + i2) * i1'));
    expect(i1 - i2, generates('i1 - i2'));
    expect(i1 - -i2, generates('i1 - -i2'));
    expect(i1 / i2, generates('i1 / i2'));
  });

  test('absolute values', () {
    expect(i2.abs(), generates('abs(i2)'));
  });

  test('round', () {
    expect(i2.round(), generates('round(i2)'));
  });
}
