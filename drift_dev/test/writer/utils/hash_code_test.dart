//@dart=2.9

import 'package:charcode/ascii.dart';
import 'package:drift_dev/src/writer/utils/hash_code.dart';
import 'package:test/test.dart';

void main() {
  test('hash code for no fields', () {
    final buffer = StringBuffer();
    const HashCodeWriter().writeHashCode([], buffer);
    expect(buffer.toString(), r'identityHashCode(this)');
  });

  test('hash code for a single field', () {
    final buffer = StringBuffer();
    const HashCodeWriter().writeHashCode(['a'], buffer);
    expect(buffer.toString(), r'a.hashCode');
  });

  test('hash code for multiple fields', () {
    final buffer = StringBuffer();
    const HashCodeWriter().writeHashCode(['a', 'b', 'c'], buffer);
    expect(buffer.toString(), r'Object.hash(a, b, c)');
  });

  test('hash code for lots of fields', () {
    final buffer = StringBuffer();
    const HashCodeWriter().writeHashCode(
        List.generate(26, (index) => String.fromCharCode($a + index)), buffer);
    expect(buffer.toString(),
        r'Object.hashAll([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z])');
  });
}
