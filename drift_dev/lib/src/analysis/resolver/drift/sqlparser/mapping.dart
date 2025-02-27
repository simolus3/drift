import 'package:analyzer/dart/element/type.dart';
import 'package:drift/drift.dart' show BuiltinDriftType;
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
    var type = switch (column.sqlType) {
      ColumnDriftType(:final builtin) => _driftTypeToParser(builtin),
      ColumnCustomType(:final custom) =>
        ResolvedType(type: BasicType.any, hints: [CustomTypeHint(custom)]),
    }
        .withNullable(column.nullable);

    if (column.typeConverter case AppliedTypeConverter c) {
      type = type.addHint(TypeConverterHint(c));
    }

    return type;
  }

  ResolvedType _driftTypeToParser(BuiltinDriftType type) {
    return switch (type) {
      BuiltinDriftType.int => const ResolvedType(type: BasicType.int),
      BuiltinDriftType.int64 =>
        const ResolvedType(type: BasicType.int, hints: [IsBigInt()]),
      BuiltinDriftType.text => const ResolvedType(type: BasicType.text),
      BuiltinDriftType.bool =>
        const ResolvedType(type: BasicType.int, hints: [IsBoolean()]),
      BuiltinDriftType.dateTime => ResolvedType(
          type: driver.options.sqliteDialect.dateTimesAsText
              ? BasicType.text
              : BasicType.int,
          hints: const [IsDateTime()],
        ),
      BuiltinDriftType.byteArray => const ResolvedType(type: BasicType.blob),
      BuiltinDriftType.double => const ResolvedType(type: BasicType.real),
      BuiltinDriftType.json => ResolvedType(
          type: driver.options.sqliteDialect.binaryJson
              ? BasicType.blob
              : BasicType.text,
        ),
    };
  }

  ColumnType toDefaultType(ResolvedType type, bool dateTimeAsText) {
    switch (type.type) {
      case null:
      case BasicType.nullType:
        return ColumnType.drift(BuiltinDriftType.text);
      case BasicType.int:
        if (type.hint<IsBoolean>() != null) {
          return ColumnType.drift(BuiltinDriftType.bool);
        } else if (!dateTimeAsText && type.hint<IsDateTime>() != null) {
          return ColumnType.drift(BuiltinDriftType.dateTime);
        } else if (type.hint<IsBigInt>() != null) {
          return ColumnType.drift(BuiltinDriftType.int64);
        }
        return ColumnType.drift(BuiltinDriftType.int);
      case BasicType.real:
        return ColumnType.drift(BuiltinDriftType.double);
      case BasicType.text:
        if (dateTimeAsText && type.hint<IsDateTime>() != null) {
          return ColumnType.drift(BuiltinDriftType.dateTime);
        }

        return ColumnType.drift(BuiltinDriftType.text);
      case BasicType.blob:
        return ColumnType.drift(BuiltinDriftType.byteArray);
      case BasicType.any:
        return ColumnType.custom(CustomColumnType(
          AnnotatedDartCode.build((b) => b.addSymbol(
              'SqliteDialect', Uri.parse('package:drift/dialect/sqlite.dart'))),
          knownTypes!.driftAny.thisType,
        ));
    }
  }

  ColumnType _toDefaultType(ResolvedType type) {
    return toDefaultType(type, driver.options.sqliteDialect.dateTimesAsText);
  }

  HasType sqlToDrift(ResolvedType? type) {
    return _HasType(type, sqlTypeToDrift(type));
  }

  ColumnType sqlTypeToDrift(ResolvedType? type) {
    if (type == null) {
      return const ColumnType.drift(BuiltinDriftType.text);
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
          knownTypes!.geopolyPolygon,
        ),
      );
    }

    return _toDefaultType(type);
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

final class _HasType extends HasType {
  final ResolvedType? type;
  @override
  final ColumnType sqlType;

  _HasType(this.type, this.sqlType);

  @override
  bool get isArray => type?.isArray ?? false;

  @override
  bool get nullable => type?.nullable ?? true;

  @override
  AppliedTypeConverter? get typeConverter {
    final hint = type?.hint<TypeConverterHint>();
    return hint?.converter;
  }
}
