import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:drift_dev/src/writer/utils/override_toString.dart';
import 'package:drift_dev/writer.dart';

class DataClassWriter {
  final DriftEntityWithResultSet table;
  final Scope scope;

  List<DriftColumn> get columns => table.columns;

  bool get isInsertable => table is DriftTable;

  late StringBuffer _buffer;

  DataClassWriter(this.table, this.scope) {
    _buffer = scope.leaf();
  }

  String get serializerType => 'ValueSerializer?';

  void write() {
    final parentClass = table.customParentClass ?? 'DataClass';
    _buffer.write('class ${table.dartTypeCode()} extends $parentClass ');

    if (isInsertable) {
      // The data class is only an insertable if we can actually insert rows
      // into the target entity.
      _buffer.writeln('implements Insertable<${table.dartTypeCode()}> {');
    } else {
      _buffer.writeln('{');
    }

    // write individual fields
    for (final column in columns) {
      if (column.documentationComment != null) {
        _buffer.write('${column.documentationComment}\n');
      }
      final modifier = scope.options.fieldModifier;
      _buffer.write('$modifier ${column.dartTypeCode()} '
          '${column.dartGetterName}; \n');
    }

    // write constructor with named optional fields

    if (!scope.options.generateMutableClasses) {
      _buffer.write('const ');
    }
    _buffer
      ..write(table.dartTypeCode())
      ..write('({')
      ..write(columns.map((column) {
        final nullableDartType = column.typeConverter != null
            ? column.typeConverter!.mapsToNullableDart(column.nullable)
            : column.nullable;

        if (nullableDartType) {
          return 'this.${column.dartGetterName}';
        } else {
          return 'required this.${column.dartGetterName}';
        }
      }).join(', '))
      ..write('});');

    if (isInsertable) {
      _writeToColumnsOverride();
      if (scope.options.dataClassToCompanions) {
        _writeToCompanion();
      }
    }

    // And a serializer and deserializer method
    _writeFromJson();
    _writeToJson();

    // And a convenience method to copy data from this class.
    _writeCopyWith();

    _writeToString();
    _writeHashCode();

    overrideEquals(
      columns.map(
          (c) => EqualityField(c.dartGetterName, isList: c.isUint8ListInDart)),
      table.dartTypeCode(),
      _buffer,
    );

    // finish class declaration
    _buffer.write('}');
  }

  void _writeFromJson() {
    final dataClassName = table.dartTypeCode();

    _buffer
      ..write('factory $dataClassName.fromJson('
          'Map<String, dynamic> json, {$serializerType serializer}'
          ') {\n')
      ..write('serializer ??= driftRuntimeOptions.defaultSerializer;\n')
      ..write('return $dataClassName(');

    for (final column in columns) {
      final getter = column.dartGetterName;
      final jsonKey = column.getJsonKey(scope.options);
      String deserialized;

      final typeConverter = column.typeConverter;
      if (typeConverter != null && typeConverter.alsoAppliesToJsonConversion) {
        final type = typeConverter.jsonType;
        final fromConverter = "serializer.fromJson<$type>(json['$jsonKey'])";
        final converterField =
            typeConverter.tableAndField(forNullableColumn: column.nullable);
        deserialized = '$converterField.fromJson($fromConverter)';
      } else {
        final type = column.dartTypeCode();

        deserialized = "serializer.fromJson<$type>(json['$jsonKey'])";
      }

      _buffer.write('$getter: $deserialized,');
    }

    _buffer.write(');}\n');

    if (scope.writer.options.generateFromJsonStringConstructor) {
      // also generate a constructor that only takes a json string
      _buffer.write('factory $dataClassName.fromJsonString(String encodedJson, '
          '{$serializerType serializer}) => '
          '$dataClassName.fromJson('
          'DataClass.parseJson(encodedJson) as Map<String, dynamic>, '
          'serializer: serializer);');
    }
  }

  void _writeToJson() {
    _buffer.write('@override Map<String, dynamic> toJson('
        '{$serializerType serializer}) {\n'
        'serializer ??= driftRuntimeOptions.defaultSerializer;\n'
        'return <String, dynamic>{\n');

    for (final column in columns) {
      final name = column.getJsonKey(scope.options);
      final getter = column.dartGetterName;
      final needsThis = getter == 'serializer';
      var value = needsThis ? 'this.$getter' : getter;
      var dartType = column.dartTypeCode();

      final typeConverter = column.typeConverter;
      if (typeConverter != null && typeConverter.alsoAppliesToJsonConversion) {
        final converterField =
            typeConverter.tableAndField(forNullableColumn: column.nullable);
        value = '$converterField.toJson($value)';
        dartType = column.jsonTypeCode();
      }

      _buffer.write("'$name': serializer.toJson<$dartType>($value),");
    }

    _buffer.write('};}');
  }

  void _writeCopyWith() {
    final dataClassName = table.dartTypeCode();
    final wrapNullableInValue = scope.options.generateValuesInCopyWith;

    _buffer.write('$dataClassName copyWith({');
    for (var i = 0; i < columns.length; i++) {
      final column = columns[i];
      final last = i == columns.length - 1;
      final isNullable = column.nullableInDart;

      final typeName = column.dartTypeCode();
      if (wrapNullableInValue && isNullable) {
        _buffer
          ..write('Value<$typeName> ${column.dartGetterName} ')
          ..write('= const Value.absent()');
      } else if (!isNullable) {
        // We always use nullable parameters in copyWith, since all parameters
        // are optional. The !isNullable check is there to avoid a duplicate
        // question mark in the type name.
        _buffer.write('$typeName? ${column.dartGetterName}');
      } else {
        _buffer.write('$typeName ${column.dartGetterName}');
      }

      if (!last) {
        _buffer.write(',');
      }
    }

    _buffer.write('}) => $dataClassName(');

    for (final column in columns) {
      // We also have a method parameter called like the getter, so we can use
      // field: field ?? this.field. If we wrapped the parameter in a `Value`,
      // we can use field.present ? field.value : this.field
      final getter = column.dartGetterName;

      if (wrapNullableInValue && column.nullableInDart) {
        _buffer
            .write('$getter: $getter.present ? $getter.value : this.$getter,');
      } else {
        _buffer.write('$getter: $getter ?? this.$getter,');
      }
    }

    _buffer.write(');');
  }

  void _writeToColumnsOverride() {
    _buffer
      ..write('@override\nMap<String, Expression> toColumns'
          '(bool nullToAbsent) {\n')
      ..write('final map = <String, Expression> {};');

    for (final column in columns) {
      // Generated column - cannot be used for inserts or updates
      if (column.isGenerated) continue;

      // We include all columns that are not null. If nullToAbsent is false, we
      // also include null columns. When generating NNBD code, we can include
      // non-nullable columns without an additional null check since we know
      // the values aren't going to be null.
      final needsNullCheck = column.nullableInDart;
      final needsScope = needsNullCheck || column.typeConverter != null;
      if (needsNullCheck) {
        _buffer.write('if (!nullToAbsent || ${column.dartGetterName} != null)');
      }
      if (needsScope) _buffer.write('{');

      final typeName = column.variableTypeCode(nullable: false);
      final mapSetter = 'map[${asDartLiteral(column.name.name)}] = '
          'Variable<$typeName>';

      if (column.typeConverter != null) {
        // apply type converter before writing the variable
        final converter = column.typeConverter;
        final fieldName =
            converter!.tableAndField(forNullableColumn: column.nullable);

        _buffer
          ..write('final converter = $fieldName;\n')
          ..write(mapSetter)
          ..write('(converter.toSql(${column.dartGetterName})');
        _buffer.write(');');
      } else {
        // no type converter. Write variable directly
        _buffer
          ..write(mapSetter)
          ..write('(')
          ..write(column.dartGetterName)
          ..write(');');
      }

      // This one closes the optional if from before.
      if (needsScope) _buffer.write('}');
    }

    _buffer.write('return map; \n}\n');
  }

  void _writeToCompanion() {
    final asTable = table as DriftTable;

    _buffer
      ..write(asTable.getNameForCompanionClass(scope.options))
      ..write(' toCompanion(bool nullToAbsent) {\n');

    _buffer
      ..write('return ')
      ..write(asTable.getNameForCompanionClass(scope.options))
      ..write('(');

    for (final column in columns) {
      // Generated columns are not parts of companions.
      if (column.isGenerated) continue;

      final dartName = column.dartGetterName;
      _buffer
        ..write(dartName)
        ..write(': ');

      final needsNullCheck = column.nullableInDart;
      if (needsNullCheck) {
        _buffer
          ..write(dartName)
          ..write(' == null && nullToAbsent ? const Value.absent() : ');
        // We'll write the non-null case afterwards
      }

      _buffer
        ..write('Value (')
        ..write(dartName)
        ..write('),');
    }

    _buffer.writeln(');\n}');
  }

  void _writeToString() {
    overrideToString(
      table.dartTypeCode(),
      [for (final column in columns) column.dartGetterName],
      _buffer,
    );
  }

  void _writeHashCode() {
    _buffer.write('@override\n int get hashCode => ');

    final fields = columns
        .map(
            (c) => EqualityField(c.dartGetterName, isList: c.isUint8ListInDart))
        .toList();
    writeHashCode(fields, _buffer);
    _buffer.write(';');
  }
}

/// Generates code mapping a row (represented as a `Map`) to positional and
/// named Dart arguments.
class RowMappingWriter {
  final List<DriftColumn> positional;
  final Map<DriftColumn, String> named;
  final DriftEntityWithResultSet table;
  final GenerationOptions options;

  /// Code to obtain an instance of a `DatabaseConnectionUser` in the generated
  /// code.
  ///
  /// This is used to lookup the connection options necessary for mapping values
  /// from SQL to Dart.
  final String databaseGetter;

  RowMappingWriter({
    required this.positional,
    required this.table,
    required this.options,
    required this.databaseGetter,
    this.named = const {},
  });

  void writeArguments(StringBuffer buffer) {
    String readAndMap(DriftColumn column) {
      final columnName = column.name.name;
      final rawData = "data['\${effectivePrefix}$columnName']";

      final sqlType = column.type.toString();
      var loadType =
          '$databaseGetter.options.types.read($sqlType, $rawData, $databaseGetter.executor.dialect)';

      if (!column.nullable) {
        loadType += '!';
      }

      // run the loaded expression though the custom converter for the final
      // result.
      if (column.typeConverter != null) {
        // stored as a static field
        final loaded = column.typeConverter!
            .tableAndField(forNullableColumn: column.nullable);
        loadType = '$loaded.fromSql($loadType)';
      }

      return loadType;
    }

    buffer.write('(');

    for (final column in positional) {
      buffer
        ..write(readAndMap(column))
        ..write(', ');
    }

    named.forEach((column, parameterName) {
      final getter = column.dartGetterName;
      buffer.write('$getter: ${readAndMap(column)}, ');
    });

    buffer.write(')');
  }
}
