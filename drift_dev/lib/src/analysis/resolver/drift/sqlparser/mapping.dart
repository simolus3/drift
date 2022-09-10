import 'package:drift/drift.dart' show DriftSqlType;
import 'package:sqlparser/sqlparser.dart';

import '../../../../analyzer/options.dart';
import '../../../results/results.dart';

/// Converts tables and types between `drift_dev` internal reprensentation and
/// the one used by the `sqlparser` package.
class TypeMapping {
  final DriftOptions options;

  TypeMapping(this.options);

  Table asSqlParserTable(DriftTable table) {
    return Table(
      name: table.schemaName,
      isStrict: table.strict,
      withoutRowId: table.withoutRowId,
      resolvedColumns: [
        for (final column in table.columns)
          TableColumn(
            column.nameInSql,
            _driftTypeToParser(column.sqlType,
                overrideHint: column.typeConverter != null
                    ? TypeConverterHint(column.typeConverter!)
                    : null),
            isGenerated: column.isGenerated,
          ),
      ],
    );
  }

  ResolvedType _driftTypeToParser(DriftSqlType type, {TypeHint? overrideHint}) {
    switch (type) {
      case DriftSqlType.int:
        return ResolvedType(type: BasicType.int, hint: overrideHint);
      case DriftSqlType.bigInt:
        return ResolvedType(
            type: BasicType.int, hint: overrideHint ?? const IsBigInt());
      case DriftSqlType.string:
        return ResolvedType(type: BasicType.text, hint: overrideHint);
      case DriftSqlType.bool:
        return ResolvedType(
            type: BasicType.int, hint: overrideHint ?? const IsBoolean());
      case DriftSqlType.dateTime:
        return ResolvedType(
          type: options.storeDateTimeValuesAsText
              ? BasicType.text
              : BasicType.int,
          hint: overrideHint ?? const IsDateTime(),
        );
      case DriftSqlType.blob:
        return ResolvedType(type: BasicType.blob, hint: overrideHint);
      case DriftSqlType.double:
        return ResolvedType(type: BasicType.real, hint: overrideHint);
    }
  }

  DriftSqlType sqlTypeToDrift(ResolvedType? type) {
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

class TypeConverterHint extends TypeHint {
  final AppliedTypeConverter converter;

  TypeConverterHint(this.converter);
}
