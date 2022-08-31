import 'package:drift/drift.dart' show DriftSqlType;
import 'package:sqlparser/sqlparser.dart';

import '../../../analyzer/options.dart';

extension MapTypeToDrift on ResolvedType? {
  DriftSqlType sqlTypeToDrift(DriftOptions options) {
    final type = this;

    if (type == null) {
      return DriftSqlType.string;
    }

    switch (type.type) {
      case null:
      case BasicType.nullType:
        return DriftSqlType.string;
      case BasicType.int:
        if (type.hint is IsBoolean) {
          return DriftSqlType.bool;
        } else if (!options.storeDateTimeValuesAsText &&
            type.hint is IsDateTime) {
          return DriftSqlType.dateTime;
        } else if (type.hint is IsBigInt) {
          return DriftSqlType.bigInt;
        }
        return DriftSqlType.int;
      case BasicType.real:
        return DriftSqlType.double;
      case BasicType.text:
        if (options.storeDateTimeValuesAsText && type.hint is IsDateTime) {
          return DriftSqlType.dateTime;
        }

        return DriftSqlType.string;
      case BasicType.blob:
        return DriftSqlType.blob;
    }
  }
}
