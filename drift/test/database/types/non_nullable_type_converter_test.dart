import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../generated/converter.dart';

void main() {
  test('test null in null aware type converters', () {
    const typeConverter = NullAwareSyncTypeConverter();
    expect(typeConverter.mapToDart(typeConverter.mapToSql(null)), null);
    expect(typeConverter.mapToSql(typeConverter.mapToDart(null)), null);
  });

  test('test value in null aware type converters', () {
    const typeConverter = NullAwareSyncTypeConverter();
    const value = SyncType.synchronized;
    expect(typeConverter.mapToDart(typeConverter.mapToSql(value)), value);
    expect(typeConverter.mapToSql(typeConverter.mapToDart(value.index)),
        value.index);
  });

  test('test invalid value in null aware type converters', () {
    const typeConverter = NullAwareSyncTypeConverter();
    const defaultValue = SyncType.locallyCreated;
    expect(typeConverter.mapToDart(-1), defaultValue);
  });

  test('can wrap existing type converter', () {
    const converter =
        NullAwareTypeConverter.wrap(EnumIndexConverter(_MyEnum.values));

    expect(converter.mapToDart(null), null);
    expect(converter.mapToSql(null), null);
    expect(converter.mapToDart(0), _MyEnum.foo);
    expect(converter.mapToSql(_MyEnum.foo), 0);
  });
}

enum _MyEnum { foo, bar }
