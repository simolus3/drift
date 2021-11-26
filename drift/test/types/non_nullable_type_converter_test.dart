import 'package:test/test.dart';

import '../data/tables/converter.dart';

void main() {
  test('test value in null aware type converters', () {
    const typeConverter = SyncTypeConverter();
    const value = SyncType.synchronized;
    expect(typeConverter.mapToDart(typeConverter.mapToSql(value)), value);
    expect(typeConverter.mapToSql(typeConverter.mapToDart(value.index)),
        value.index);
  });

  test('test invalid value in null aware type converters', () {
    const typeConverter = SyncTypeConverter();
    const defaultValue = SyncType.locallyCreated;
    expect(typeConverter.mapToDart(-1), defaultValue);
  });
}
