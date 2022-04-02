import 'package:drift/drift.dart';

enum SyncType {
  locallyCreated,
  locallyUpdated,
  synchronized,
}

class SyncTypeConverter extends TypeConverter<SyncType, int> {
  const SyncTypeConverter();

  @override
  SyncType? mapToDart(int? fromDb) {
    if (fromDb == null) return null;

    return SyncType.values[fromDb];
  }

  @override
  int? mapToSql(SyncType? value) {
    return value?.index;
  }
}

class NullAwareSyncTypeConverter extends NullAwareTypeConverter<SyncType, int> {
  const NullAwareSyncTypeConverter();

  @override
  SyncType requireMapToDart(int fromDb) {
    const values = SyncType.values;
    if (fromDb < 0 || fromDb >= values.length) {
      return SyncType.locallyCreated;
    }
    return values[fromDb];
  }

  @override
  int requireMapToSql(SyncType value) {
    return value.index;
  }
}
