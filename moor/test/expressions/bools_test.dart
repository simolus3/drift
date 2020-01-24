import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/utils/expect_equality.dart';
import '../data/utils/expect_generated.dart';

// ignore_for_file: deprecated_member_use_from_same_package

void main() {
  final a = GeneratedBoolColumn('a', 'tbl', false);
  final b = GeneratedBoolColumn('b', 'tbl', false);

  test('boolean expressions via operators', () {
    expect(a | b, generates('a OR b'));
    expect(a & b, generates('a AND b'));
    expect(a.not(), generates('NOT a'));

    expectEquals(a & b, a & b);
    expectNotEquals(a | b, b | a);
  });

  test('boolean expressions via top-level methods', () {
    expect(or(a, b), generates('a OR b'));
    expect(and(a, b), generates('a AND b'));
    expect(not(a), generates('NOT a'));

    expectEquals(not(a), not(a));
    expectNotEquals(not(a), not(b));
  });
}
