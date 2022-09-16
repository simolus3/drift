import 'package:drift_dev/src/writer/utils/hash_and_equals.dart';
import 'package:test/test.dart';

void main() {
  test('overrides equals on class without fields', () {
    final buffer = StringBuffer();
    overrideEquals([], 'Foo', buffer);

    expect(
        buffer.toString(),
        '@override\nbool operator ==(Object other) => '
        'identical(this, other) || (other is Foo);\n');
  });

  test('overrides equals on class with fields', () {
    final buffer = StringBuffer();
    overrideEquals([
      EqualityField('a'),
      EqualityField('b', isList: true),
      EqualityField('c'),
    ], 'Foo', buffer);

    expect(
        buffer.toString(),
        '@override\nbool operator ==(Object other) => '
        'identical(this, other) || (other is Foo && '
        r'other.a == this.a && $driftBlobEquality.equals(other.b, this.b) && '
        'other.c == this.c);\n');
  });
}
