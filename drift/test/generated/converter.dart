import 'package:drift/drift.dart';

class CustomTextType implements CustomSqlType<String> {
  const CustomTextType();

  @override
  String mapToSqlLiteral(String dartValue) {
    final escapedChars = dartValue.replaceAll('\'', '\'\'');
    return "'$escapedChars'";
  }

  @override
  Object mapToSqlParameter(String dartValue) {
    return dartValue;
  }

  @override
  String read(Object fromSql) {
    return fromSql.toString();
  }

  @override
  String sqlTypeName(GenerationContext context) {
    // Still has text column affinity, but can be used to verify that the type
    // really is used.
    return 'MY_TEXT';
  }
}

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
