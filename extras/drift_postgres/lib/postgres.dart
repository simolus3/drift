/// PostgreSQL
@experimental
library drift.postgres;

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'src/types.dart';

export 'src/pg_database.dart';

typedef UuidColumn = Column<UuidValue>;

final class PgTypes {
  PgTypes._();

  static const CustomSqlType<UuidValue> uuid = UuidType();
}

/// Calls the `gen_random_uuid` function in postgres.
Expression<UuidValue> genRandomUuid() {
  return FunctionCallExpression('gen_random_uuid', []);
}
