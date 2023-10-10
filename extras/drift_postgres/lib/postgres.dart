/// PostgreSQL
@experimental
library drift.postgres;

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:uuid/uuid.dart';

import 'src/types.dart';

export 'src/pg_database.dart';
export 'package:uuid/uuid_value.dart' show UuidValue;

typedef UuidColumn = Column<UuidValue>;
typedef IntervalColumn = Column<Duration>;
typedef JsonColumn = Column<Object>;
typedef PointColumn = Column<PgPoint>;

final class PgTypes {
  PgTypes._();

  static const CustomSqlType<UuidValue> uuid = UuidType();
  static const CustomSqlType<Duration> interval = IntervalType();
  static const CustomSqlType<Object> json =
      PostgresType(type: PgDataType.json, name: 'json');
  static const CustomSqlType<Object> jsonb =
      PostgresType(type: PgDataType.json, name: 'jsonb');
  static const CustomSqlType<PgPoint> point = PointType();
}

/// Calls the `gen_random_uuid` function in postgres.
Expression<UuidValue> genRandomUuid() {
  return FunctionCallExpression('gen_random_uuid', []);
}
