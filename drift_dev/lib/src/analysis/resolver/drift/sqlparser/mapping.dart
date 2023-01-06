import 'package:analyzer/dart/element/type.dart';
import 'package:drift/drift.dart' show DriftSqlType;
import 'package:sqlparser/sqlparser.dart';

import '../../../driver/driver.dart';
import '../../../results/results.dart';
import '../../dart/helper.dart';
import '../../shared/dart_types.dart';
import '../element_resolver.dart';

/// Converts tables and types between `drift_dev` internal reprensentation and
/// the one used by the `sqlparser` package.
class TypeMapping {
  final DriftAnalysisDriver driver;

  TypeMapping(this.driver);

  SqlEngine newEngineWithTables(Iterable<DriftElement> references) {
    final engine = driver.newSqlEngine();

    for (final reference in references) {
      if (reference is DriftTable) {
        engine.registerTable(driver.typeMapping.asSqlParserTable(reference));
      } else if (reference is DriftView) {
        engine.registerView(driver.typeMapping.asSqlParserView(reference));
      }
    }

    return engine;
  }

  Table asSqlParserTable(DriftTable table) {
    final columns = [
      for (final column in table.columns)
        TableColumn(
          column.nameInSql,
          _columnType(column),
          isGenerated: column.isGenerated,
        ),
    ];

    final recognizedVirtualTable = table.virtualTableData?.recognized;
    if (recognizedVirtualTable is DriftFts5Table) {
      return Fts5Table(
        name: table.schemaName,
        columns: columns,
        contentTable: recognizedVirtualTable.externalContentTable?.schemaName,
        contentRowId:
            recognizedVirtualTable.externalContentRowId?.nameInSql ?? 'rowid',
      );
    } else {
      return Table(
        name: table.schemaName,
        isStrict: table.strict,
        withoutRowId: table.withoutRowId,
        resolvedColumns: columns,
      );
    }
  }

  View asSqlParserView(DriftView view) {
    return View(
      name: view.schemaName,
      resolvedColumns: [
        for (final column in view.columns)
          ViewColumn(
            _SimpleColumn(column.nameInSql, _columnType(column)),
            _columnType(column),
            column.nameInSql,
          ),
      ],
    );
  }

  ResolvedType _columnType(DriftColumn column) {
    return _driftTypeToParser(column.sqlType,
            overrideHint: column.typeConverter != null
                ? TypeConverterHint(column.typeConverter!)
                : null)
        .withNullable(column.nullable);
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
          type: driver.options.storeDateTimeValuesAsText
              ? BasicType.text
              : BasicType.int,
          hint: overrideHint ?? const IsDateTime(),
        );
      case DriftSqlType.blob:
        return ResolvedType(type: BasicType.blob, hint: overrideHint);
      case DriftSqlType.double:
        return ResolvedType(type: BasicType.real, hint: overrideHint);
      case DriftSqlType.any:
        return ResolvedType(type: BasicType.any, hint: overrideHint);
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
        } else if (!driver.options.storeDateTimeValuesAsText &&
            type.hint is IsDateTime) {
          return DriftSqlType.dateTime;
        } else if (type.hint is IsBigInt) {
          return DriftSqlType.bigInt;
        }
        return DriftSqlType.int;
      case BasicType.real:
        return DriftSqlType.double;
      case BasicType.text:
        if (driver.options.storeDateTimeValuesAsText &&
            type.hint is IsDateTime) {
          return DriftSqlType.dateTime;
        }

        return DriftSqlType.string;
      case BasicType.blob:
        return DriftSqlType.blob;
      case BasicType.any:
        return DriftSqlType.any;
    }
  }
}

/// Creates a [TypeFromText] implementation that will look up type converters
/// for `ENUM` and `ENUMNAME` column.
TypeFromText enumColumnFromText(
    Map<String, DartType> knownTypes, KnownDriftTypes helper) {
  return (String typeName) {
    final match = FoundReferencesInSql.enumRegex.firstMatch(typeName);

    if (match != null) {
      final isStoredAsName = match.group(1) != null;
      final type = knownTypes[match.group(2)];

      if (type != null) {
        return ResolvedType(
          type: isStoredAsName ? BasicType.text : BasicType.int,
          hint: TypeConverterHint(
            readEnumConverter(
              (_) {},
              type,
              isStoredAsName ? EnumType.textEnum : EnumType.intEnum,
              helper,
            )..owningColumn = null,
          ),
        );
      }
    }
    return null;
  };
}

class TypeConverterHint extends TypeHint {
  final AppliedTypeConverter converter;

  TypeConverterHint(this.converter);
}

class _SimpleColumn extends Column with ColumnWithType {
  @override
  final String name;
  @override
  final ResolvedType type;

  _SimpleColumn(this.name, this.type);
}
