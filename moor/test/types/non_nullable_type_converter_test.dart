import 'package:test/test.dart';

import '../data/tables/converter.dart';

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
}
