import 'package:moor/extensions/moor_ffi.dart';
import 'package:moor/src/runtime/query_builder/query_builder.dart';
import 'package:test/test.dart';

import '../data/utils/expect_generated.dart';

void main() {
  final a = GeneratedRealColumn('a', null, false);
  final b = GeneratedRealColumn('b', null, false);

  test('pow', () {
    expect(sqlPow(a, b), generates('pow(a, b)'));
  });

  test('sqrt', () => expect(sqlSqrt(a), generates('sqrt(a)')));
  test('sin', () => expect(sqlSin(a), generates('sin(a)')));
  test('cos', () => expect(sqlCos(a), generates('cos(a)')));
  test('tan', () => expect(sqlTan(a), generates('tan(a)')));
  test('asin', () => expect(sqlAsin(a), generates('asin(a)')));
  test('acos', () => expect(sqlAcos(a), generates('acos(a)')));
  test('atan', () => expect(sqlAtan(a), generates('atan(a)')));
}
