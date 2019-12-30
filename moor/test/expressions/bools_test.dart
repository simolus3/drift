import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/utils/expect_equality.dart';
import '../data/utils/expect_generated.dart';

// ignore_for_file: deprecated_member_use_from_same_package

void main() {
  final a = GeneratedBoolColumn('a', 'tbl', false);
  final b = GeneratedBoolColumn('b', 'tbl', false);

  test('boolean expressions via operators', () {
    (a | b).expectGenerates('a OR b');
    (a & b).expectGenerates('a AND b');
    a.not().expectGenerates('NOT a');

    expectEquals(a & b, a & b);
    expectNotEquals(a | b, b | a);
  });

  test('boolean expressions via top-level methods', () {
    or(a, b).expectGenerates('a OR b');
    and(a, b).expectGenerates('a AND b');
    not(a).expectGenerates('NOT a');

    expectEquals(not(a), not(a));
    expectNotEquals(not(a), not(b));
  });
}
