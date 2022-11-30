import 'package:drift/drift.dart';
import 'package:test/test.dart';

enum _MyEnum { one, two, three }

void main() {
  const converter = EnumNameConverter(_MyEnum.values);
  const values = {
    _MyEnum.one: 'one',
    _MyEnum.two: 'two',
    _MyEnum.three: 'three'
  };

  group('encodes', () {
    values.forEach((key, value) {
      test('$key as $value', () => expect(converter.toSql(key), value));
    });
  });

  group('decodes', () {
    values.forEach((key, value) {
      test('$key as $value', () => expect(converter.fromSql(value), key));
    });
  });
}
