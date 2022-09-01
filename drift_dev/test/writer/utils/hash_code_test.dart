import 'package:charcode/ascii.dart';
import 'package:drift_dev/src/writer/utils/hash_and_equals.dart';
import 'package:test/test.dart';

void main() {
  test('hash code for no fields', () {
    final buffer = StringBuffer();
    writeHashCode([], buffer);
    expect(buffer.toString(), r'identityHashCode(this)');
  });

  test('hash code for a single field - not a list', () {
    final buffer = StringBuffer();
    writeHashCode([EqualityField('a')], buffer);
    expect(buffer.toString(), r'a.hashCode');
  });

  test('hash code for a single field - list', () {
    final buffer = StringBuffer();
    writeHashCode([EqualityField('a', isList: true)], buffer);
    expect(buffer.toString(), r'$driftBlobEquality.hash(a)');
  });

  test('hash code for multiple fields', () {
    final buffer = StringBuffer();
    writeHashCode([
      EqualityField('a'),
      EqualityField('b', isList: true),
      EqualityField('c'),
    ], buffer);
    expect(buffer.toString(), r'Object.hash(a, $driftBlobEquality.hash(b), c)');
  });

  test('hash code for lots of fields', () {
    final buffer = StringBuffer();
    writeHashCode(
        List.generate(
            26, (index) => EqualityField(String.fromCharCode($a + index))),
        buffer);
    expect(
      buffer.toString(),
      r'Object.hashAll([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, '
      's, t, u, v, w, x, y, z])',
    );
  });
}
