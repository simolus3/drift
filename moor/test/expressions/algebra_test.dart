import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/utils/expect_generated.dart';

void main() {
  final i1 = GeneratedIntColumn('i1', 'tbl', true);
  final i2 = GeneratedIntColumn('i2', 'tbl', true);
  final s1 = GeneratedTextColumn('s1', 'tbl', true);
  final s2 = GeneratedTextColumn('s2', 'tbl', true);

  test('arithmetic test', () {
    (i1 + i2 * i1).expectGenerates('i1 + i2 * i1');
    (i1 + i2 * i1).expectGenerates('i1 + i2 * i1');
    ((i1 + i2) * i1).expectGenerates('(i1 + i2) * i1');
    (i1 - i2).expectGenerates('i1 - i2');
    (i1 - -i2).expectGenerates('i1 - -i2');
    (i1 / i2).expectGenerates('i1 / i2');
  });

  test('string concatenation', () {
    (s1 + s2).expectGenerates('s1 || s2');
  });
}
