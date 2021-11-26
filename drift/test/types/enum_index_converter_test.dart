import 'package:drift/drift.dart';
import 'package:test/test.dart';

enum _MyEnum { one, two, three }

void main() {
  const converter = NullableEnumIndexConverter<_MyEnum>(_MyEnum.values);
  const values = {_MyEnum.one: 0, _MyEnum.two: 1, _MyEnum.three: 2, null: null};

  group('encodes', () {
    values.forEach((key, value) {
      test('$key as $value', () => expect(converter.mapToSql(key), value));
    });
  });

  group('decodes', () {
    values.forEach((key, value) {
      test('$key as $value', () => expect(converter.mapToDart(value), key));
    });
  });
}
