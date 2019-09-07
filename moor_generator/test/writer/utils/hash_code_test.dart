import 'package:moor_generator/src/writer/utils/hash_code.dart';
import 'package:test_api/test_api.dart';

void main() {
  test('hash code for no fields', () {
    final buffer = StringBuffer();
    HashCodeWriter().writeHashCode([], buffer);
    expect(buffer.toString(), r'identityHashCode(this)');
  });

  test('hash code for a single field', () {
    final buffer = StringBuffer();
    HashCodeWriter().writeHashCode(['a'], buffer);
    expect(buffer.toString(), r'$mrjf(a.hashCode)');
  });

  test('hash code for multiple fields', () {
    final buffer = StringBuffer();
    HashCodeWriter().writeHashCode(['a', 'b', 'c'], buffer);
    expect(buffer.toString(),
        r'$mrjf($mrjc(a.hashCode, $mrjc(b.hashCode, c.hashCode)))');
  });
}
