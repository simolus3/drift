import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/utils/expect_equality.dart';
import '../data/utils/expect_generated.dart';

void main() {
  final i1 = GeneratedIntColumn('i1', 'tbl', true);
  final i2 = GeneratedIntColumn('i2', 'tbl', true);
  final s1 = GeneratedTextColumn('s1', 'tbl', true);
  final s2 = GeneratedTextColumn('s2', 'tbl', true);

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
}
