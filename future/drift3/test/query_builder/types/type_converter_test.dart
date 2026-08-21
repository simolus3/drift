import 'dart:convert';

import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import '../../generated/converter.dart';
import '../../generated/todos.dart';

enum _MyEnum { one, two, three }

void main() {
  test('TypeConverter.legacyJson', () {
    // ignore: deprecated_member_use
    final converter = TypeConverter.legacyJson(
      fromJson: (json) => _MyEnum.values.byName(json as String),
      toJson: (member) => member.name,
    );

    // ignore: deprecated_member_use
    final customCodec = TypeConverter.legacyJson(
      fromJson: (json) => _MyEnum.values.byName(json as String),
      json: JsonCodec(toEncodable: (object) => 'custom'),
    );

    const values = {
      _MyEnum.one: '"one"',
      _MyEnum.two: '"two"',
      _MyEnum.three: '"three"',
    };

    values.forEach((key, value) {
      expect(converter.toSql(key), value);
      expect(converter.fromSql(value), key);
      expect(converter.toJson(key), value);
      expect(converter.fromJson(value), key);

      expect(customCodec.toSql(key), '"custom"');
      expect(customCodec.fromSql(value), key);
    });
  });

  test('TypeConverter.json', () {
    final converter = TypeConverter.json(
      fromJson: (json) => _MyEnum.values.byName(json as String),
      toJson: (member) => member.name,
    );

    const values = {
      _MyEnum.one: 'one',
      _MyEnum.two: 'two',
      _MyEnum.three: 'three',
    };

    values.forEach((key, value) {
      expect(converter.toSql(key), DatabaseJson(value));
      expect(converter.fromSql(DatabaseJson(value)), key);
      expect(converter.toJson(key), value);
      expect(converter.fromJson(value), key);
    });
  });

  test('TypeConverter.extensionType', () {
    final converter = TypeConverter.extensionType<RowId, int>();

    expect(converter.toSql(RowId(123)), 123);
    expect(converter.fromSql(15), RowId(15));
    expect(converter.fromSql(15), 15);
    expect(converter.fromJson(16), RowId(16));
    expect(converter.toJson(RowId(124)), 124);
  });

  group('enum name', () {
    const converter = EnumNameConverter(_MyEnum.values);
    const values = {
      _MyEnum.one: 'one',
      _MyEnum.two: 'two',
      _MyEnum.three: 'three',
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
  });

  group('enum index', () {
    const converter = EnumIndexConverter(_MyEnum.values);
    const values = {_MyEnum.one: 0, _MyEnum.two: 1, _MyEnum.three: 2};

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
  });

  group('null aware', () {
    test('test null in null aware type converters', () {
      const typeConverter = NullAwareSyncTypeConverter();
      expect(typeConverter.fromSql(typeConverter.toSql(null)), null);
      expect(typeConverter.toSql(typeConverter.fromSql(null)), null);
    });

    test('test value in null aware type converters', () {
      const typeConverter = NullAwareSyncTypeConverter();
      const value = SyncType.synchronized;
      expect(typeConverter.fromSql(typeConverter.toSql(value)), value);
      expect(
        typeConverter.toSql(typeConverter.fromSql(value.index)),
        value.index,
      );
    });

    test('test invalid value in null aware type converters', () {
      const typeConverter = NullAwareSyncTypeConverter();
      const defaultValue = SyncType.locallyCreated;
      expect(typeConverter.fromSql(-1), defaultValue);
    });

    test('can wrap existing type converter', () {
      const converter = NullAwareTypeConverter.wrap(
        EnumIndexConverter(_MyEnum.values),
      );

      expect(converter.fromSql(null), null);
      expect(converter.toSql(null), null);
      expect(converter.fromSql(0), _MyEnum.one);
      expect(converter.toSql(_MyEnum.one), 0);
    });
  });
}
