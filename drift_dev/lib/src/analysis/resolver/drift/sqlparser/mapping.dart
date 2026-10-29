import 'package:analyzer/dart/element/type.dart';
import 'package:sqlparser/sqlparser.dart';

import '../../../dialect.dart';
import '../../../driver/driver.dart';
import '../../../results/results.dart';
import '../../dart/helper.dart';
import '../../shared/dart_types.dart';
import '../element_resolver.dart';

/// Converts tables and types between `drift_dev` internal reprensentation and
/// the one used by the `sqlparser` package.
class TypeMapping {
  final DriftAnalysisDriver driver;
  final KnownDriftTypes? knownTypes;

  TypeMapping(this.driver, this.knownTypes);

  SqlEngine newEngineWithTables(Iterable<DriftElement> references) {
    final engine = driver.newSqlEngine();

    for (final reference in references) {
      if (reference is DriftTable) {
        engine.registerTable(asSqlParserTable(reference));
      } else if (reference is DriftView) {
        engine.registerView(asSqlParserView(reference));
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
    var type = _driftTypeToParser(
      column.sqlType.builtin,
    ).withNullable(column.nullable);

    type = switch (column.sqlType) {
      ColumnDriftType() => type,
      ColumnCustomType(:final custom) => type.addHint(CustomTypeHint(custom)),
    };

    if (column.typeConverter case AppliedTypeConverter c) {
      type = type.addHint(TypeConverterHint(c));
    }

    return type;
  }

  ResolvedType _driftTypeToParser(BuiltinType type) {
    return switch (type) {
      BuiltinType.int => const ResolvedType(type: BasicType.int),
      BuiltinType.bigInt => const ResolvedType(
        type: BasicType.int,
        hints: [IsBigInt()],
      ),
      BuiltinType.string => const ResolvedType(type: BasicType.text),
      BuiltinType.bool => const ResolvedType(
        type: BasicType.int,
        hints: [IsBoolean()],
      ),
      BuiltinType.dateTime => _resolveDateTimeType(),
      BuiltinType.blob => const ResolvedType(type: BasicType.blob),
      BuiltinType.double => const ResolvedType(type: BasicType.real),
      BuiltinType.any => const ResolvedType(type: BasicType.any),
      BuiltinType.json => _resolveJsonType(),
    };
  }

  ResolvedType _resolveDateTimeType() {
    var storeDateTimeValuesAsText = driver.options.storeDateTimeValuesAsText;

    if (driver.options.drift3Preview) {
      if (driver.options.drift3Dialects
              .whereType<Drift3SqliteDialect>()
              .firstOrNull
          case final sqlite3Dialect?) {
        storeDateTimeValuesAsText = sqlite3Dialect.storeDateTimesAsText;
      }
    }

    return ResolvedType(
      type: storeDateTimeValuesAsText ? BasicType.text : BasicType.int,
      hints: const [IsDateTime()],
    );
  }

  ResolvedType _resolveJsonType() {
    var useBinaryJsonRepresentation = true;

    if (driver.options.drift3Preview) {
      if (driver.options.drift3Dialects
              .whereType<Drift3SqliteDialect>()
              .firstOrNull
          case final sqlite3Dialect?) {
        useBinaryJsonRepresentation =
            sqlite3Dialect.useBinaryJsonRepresentation;
      }
    }

    return ResolvedType(
      type: useBinaryJsonRepresentation ? BasicType.blob : BasicType.text,
    );
  }

  static BuiltinType toDefaultType(ResolvedType type, bool dateTimeAsText) {
    switch (type.type) {
      case null:
      case BasicType.nullType:
        return BuiltinType.string;
      case BasicType.int:
        if (type.hint<IsBoolean>() != null) {
          return BuiltinType.bool;
        } else if (!dateTimeAsText && type.hint<IsDateTime>() != null) {
          return BuiltinType.dateTime;
        } else if (type.hint<IsBigInt>() != null) {
          return BuiltinType.bigInt;
        }
        return BuiltinType.int;
      case BasicType.real:
        return BuiltinType.double;
      case BasicType.text:
        if (dateTimeAsText && type.hint<IsDateTime>() != null) {
          return BuiltinType.dateTime;
        }

        return BuiltinType.string;
      case BasicType.blob:
        return BuiltinType.blob;
      case BasicType.any:
        return BuiltinType.any;
    }
  }

  BuiltinType _toDefaultType(ResolvedType type) {
    return toDefaultType(type, driver.options.storeDateTimeValuesAsText);
  }

  ColumnType sqlTypeToDrift(ResolvedType? type) {
    if (type == null) {
      return const ColumnType.drift(BuiltinType.string);
    }

    final customHint = type.hint<CustomTypeHint>();
    if (customHint != null) {
      return ColumnType.custom(customHint.type);
    }

    if (type.hint<IsGeopolyPolygon>() != null) {
      return ColumnType.custom(
        CustomColumnType(
          AnnotatedDartCode.importedSymbol(
            Uri.parse('package:drift/extensions/geopoly.dart'),
            'const GeopolyPolygonType()',
          ),
          knownTypes!.geopolyPolygon!,
        ),
      );
    }

    return ColumnType.drift(_toDefaultType(type));
  }

  HasType resolveSqlType(ResolvedType? type) {
    final columnType = sqlTypeToDrift(type);
    return _ResolvedTypeFromSql(
      isArray: type?.isArray ?? false,
      nullable: type?.nullable ?? true,
      sqlType: columnType,
      typeConverter: null,
    );
  }
}

final class _ResolvedTypeFromSql implements HasType {
  @override
  final bool isArray;
  @override
  final bool nullable;
  @override
  final ColumnType sqlType;
  @override
  final AppliedTypeConverter? typeConverter;

  _ResolvedTypeFromSql({
    required this.isArray,
    required this.nullable,
    required this.sqlType,
    required this.typeConverter,
  });
}

/// Creates a [TypeFromText] implementation that will look up type converters
/// for `ENUM` and `ENUMNAME` column.
TypeFromText enumColumnFromText(
  Map<String, DartType> knownTypes,
  KnownDriftTypes helper,
) {
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
