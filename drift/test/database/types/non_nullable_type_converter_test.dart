import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../generated/converter.dart';

void main() {
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
        typeConverter.toSql(typeConverter.fromSql(value.index)), value.index);
  });

  test('test invalid value in null aware type converters', () {
    const typeConverter = NullAwareSyncTypeConverter();
    const defaultValue = SyncType.locallyCreated;
    expect(typeConverter.fromSql(-1), defaultValue);
  });

  test('can wrap existing type converter', () {
    const converter =
        NullAwareTypeConverter.wrap(EnumIndexConverter(_MyEnum.values));

    expect(converter.fromSql(null), null);
    expect(converter.toSql(null), null);
    expect(converter.fromSql(0), _MyEnum.foo);
    expect(converter.toSql(_MyEnum.foo), 0);
  });
}

enum _MyEnum { foo, bar }
