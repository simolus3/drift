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
    var type = _driftTypeToParser(column.sqlType.builtin)
        .withNullable(column.nullable);

    if (column.sqlType.isCustom) {
      type = type.addHint(CustomTypeHint(column.sqlType.custom!));
    }
    if (column.typeConverter case AppliedTypeConverter c) {
      type = type.addHint(TypeConverterHint(c));
    }

    return type;
  }

  ResolvedType _driftTypeToParser(DriftSqlType type) {
    return switch (type) {
      DriftSqlType.int => const ResolvedType(type: BasicType.int),
      DriftSqlType.bigInt =>
        const ResolvedType(type: BasicType.int, hints: [IsBigInt()]),
      DriftSqlType.string => const ResolvedType(type: BasicType.text),
      DriftSqlType.bool =>
        const ResolvedType(type: BasicType.int, hints: [IsBoolean()]),
      DriftSqlType.dateTime => ResolvedType(
          type: driver.options.storeDateTimeValuesAsText
              ? BasicType.text
              : BasicType.int,
          hints: const [IsDateTime()],
        ),
      DriftSqlType.blob => const ResolvedType(type: BasicType.blob),
      DriftSqlType.double => const ResolvedType(type: BasicType.real),
      DriftSqlType.any => const ResolvedType(type: BasicType.any),
    };
  }

  DriftSqlType _toDefaultType(ResolvedType type) {
    switch (type.type) {
      case null:
      case BasicType.nullType:
        return DriftSqlType.string;
      case BasicType.int:
        if (type.hint<IsBoolean>() != null) {
          return DriftSqlType.bool;
        } else if (!driver.options.storeDateTimeValuesAsText &&
            type.hint<IsDateTime>() != null) {
          return DriftSqlType.dateTime;
        } else if (type.hint<IsBigInt>() != null) {
          return DriftSqlType.bigInt;
        }
        return DriftSqlType.int;
      case BasicType.real:
        return DriftSqlType.double;
      case BasicType.text:
        if (driver.options.storeDateTimeValuesAsText &&
            type.hint<IsDateTime>() != null) {
          return DriftSqlType.dateTime;
        }

        return DriftSqlType.string;
      case BasicType.blob:
        return DriftSqlType.blob;
      case BasicType.any:
        return DriftSqlType.any;
    }
  }

  ColumnType sqlTypeToDrift(ResolvedType? type) {
    if (type == null) {
      return const ColumnType.drift(DriftSqlType.string);
    }

    final customHint = type.hint<CustomTypeHint>();
    if (customHint != null) {
      return ColumnType.custom(customHint.type);
    }

    return ColumnType.drift(_toDefaultType(type));
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
          hints: [
            TypeConverterHint(
              readEnumConverter(
                (_) {},
                type,
                isStoredAsName ? EnumType.textEnum : EnumType.intEnum,
                helper,
              )..owningColumn = null,
            ),
          ],
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

class CustomTypeHint extends TypeHint {
  final CustomColumnType type;

  CustomTypeHint(this.type);
}

class _SimpleColumn extends Column implements ColumnWithType {
  @override
  final String name;
  @override
  final ResolvedType type;

  _SimpleColumn(this.name, this.type);
}
