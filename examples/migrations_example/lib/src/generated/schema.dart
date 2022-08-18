// GENERATED CODE, DO NOT EDIT BY HAND.
//@dart=2.12
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
import 'schema_v6.dart' as v6;
import 'schema_v2.dart' as v2;
import 'schema_v7.dart' as v7;
import 'schema_v3.dart' as v3;
import 'schema_v4.dart' as v4;
import 'schema_v1.dart' as v1;
import 'schema_v5.dart' as v5;

class GeneratedHelper implements SchemaInstantiationHelper {
  @override
  GeneratedDatabase databaseForVersion(QueryExecutor db, int version) {
    switch (version) {
      case 6:
        return v6.DatabaseAtV6(db);
      case 2:
        return v2.DatabaseAtV2(db);
      case 7:
        return v7.DatabaseAtV7(db);
      case 3:
        return v3.DatabaseAtV3(db);
      case 4:
        return v4.DatabaseAtV4(db);
      case 1:
        return v1.DatabaseAtV1(db);
      case 5:
        return v5.DatabaseAtV5(db);
      default:
        throw MissingSchemaException(version, const {6, 2, 7, 3, 4, 1, 5});
    }
  }
}
