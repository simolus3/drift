import 'package:moor/moor.dart';

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
