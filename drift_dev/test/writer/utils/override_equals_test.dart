import 'package:drift_dev/src/writer/utils/override_equals.dart';
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
    overrideEquals(['a', 'b', 'c'], 'Foo', buffer);

    expect(
        buffer.toString(),
        '@override\nbool operator ==(Object other) => '
        'identical(this, other) || (other is Foo && '
        'other.a == this.a && other.b == this.b && other.c == this.c);\n');
  });
}
