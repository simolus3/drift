import 'package:drift/drift.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:uuid/uuid.dart';

class UuidType implements CustomSqlType<UuidValue> {
  const UuidType();

  @override
  String mapToSqlLiteral(UuidValue dartValue) {
    // UUIDs can't contain escape characters, so we don't check these values.
    return "'${dartValue.uuid}'";
  }

  @override
  Object mapToSqlParameter(UuidValue dartValue) {
    return PgTypedParameter(PgDataType.uuid, dartValue.uuid);
  }

  @override
  UuidValue read(Object fromSql) {
    return UuidValue(fromSql as String);
  }

  @override
  String sqlTypeName(GenerationContext context) {
    return 'uuid';
  }
}
