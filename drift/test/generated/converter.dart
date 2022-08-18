import 'package:drift/drift.dart';

enum SyncType {
  locallyCreated,
  locallyUpdated,
  synchronized,
}

class SyncTypeConverter extends TypeConverter<SyncType, int> {
  const SyncTypeConverter();

  @override
  SyncType fromSql(int fromDb) {
    return SyncType.values[fromDb];
  }

  @override
  int toSql(SyncType value) {
    return value.index;
  }
}

class NullAwareSyncTypeConverter extends NullAwareTypeConverter<SyncType, int> {
  const NullAwareSyncTypeConverter();

  @override
  SyncType requireFromSql(int fromDb) {
    const values = SyncType.values;
    if (fromDb < 0 || fromDb >= values.length) {
      return SyncType.locallyCreated;
    }
    return values[fromDb];
  }

  @override
  int requireToSql(SyncType value) {
    return value.index;
  }
}
