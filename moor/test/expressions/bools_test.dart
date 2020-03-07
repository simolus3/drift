import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/utils/expect_equality.dart';
import '../data/utils/expect_generated.dart';

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
}
