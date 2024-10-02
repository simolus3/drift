import '../../analysis/results/results.dart';
import '../../utils/string_escaper.dart';
import '../utils/hash_and_equals.dart';
import '../utils/override_toString.dart';
import '../writer.dart';

class DataClassWriter {
  final DriftElementWithResultSet table;
  final Scope scope;

  List<DriftColumn> get columns => table.columns;

  bool get isInsertable => table is DriftTable;

  final TextEmitter _emitter;

  StringBuffer get _buffer => _emitter.buffer;

  DataClassWriter(this.table, this.scope) : _emitter = scope.leaf();

  String get serializerType => _emitter.drift('ValueSerializer?');

  String _columnType(DriftColumn column) {
    return _emitter.dartCode(_emitter.dartType(column));
  }

  String _jsonType(DriftColumn column) {
    final converter = column.typeConverter;
    if (converter != null && converter.alsoAppliesToJsonConversion) {
      final nullable = converter.canBeSkippedForNulls && column.nullable;
      final code = AnnotatedDartCode([
        ...AnnotatedDartCode.type(converter.jsonType!).elements,
        if (nullable) const DartLexeme('?'),
      ]);

      return _emitter.dartCode(code);
    } else {
      return _columnType(column);
    }
  }

  String _converter(DriftColumn column) {
    return _emitter.dartCode(_emitter.writer
        .readConverter(column.typeConverter!, forNullable: column.nullable));
  }

  void write() {
    final customParent = table.customParentClass;
    final parentClass = customParent != null
        ? _emitter.dartCode(customParent.parentClass)
        : _emitter.drift('DataClass');
    _buffer.write('class ${table.nameOfRowClass} extends $parentClass ');

    var hasImplementsClause = false;
    if (isInsertable) {
      if (scope.options.writeToColumnsMixins) {
        _buffer.writeln('with ${table.toColumnsMixin} ');
      } else {
        // The data class is only an insertable if we can actually insert rows
        // into the target entity.
        final type = _emitter.dartCode(_emitter.writer.rowType(table));

        hasImplementsClause = true;
        _buffer.writeln('implements ${_emitter.drift('Insertable')}<$type> ');
      }
    }

    if (table.interfacesForRowClass.isNotEmpty) {
      if (!hasImplementsClause) {
        _buffer.write(' implements ');
      } else {
        _buffer.write(', ');
      }

      _buffer
          .write(table.interfacesForRowClass.map(_emitter.dartCode).join(', '));
    }

    _buffer.writeln('{'); // start of clas

    // write individual fields
    for (final column in columns) {
      if (column.documentationComment != null) {
        _buffer.write('${column.documentationComment}\n');
      }
      if (scope.options.writeToColumnsMixins) {
        _buffer.writeln('@override');
      }
      final modifier = scope.options.fieldModifier;
      _buffer.writeln('$modifier ${_columnType(column)} ${column.nameInDart};');
    }

    // write constructor with named optional fields
    if (!scope.options.generateMutableClasses &&
        customParent?.isConst != false) {
      _buffer.write('const ');
    }
    _emitter
      ..write(table.nameOfRowClass)
      ..write('({')
      ..write(columns.map((column) {
        final nullableDartType = column.typeConverter != null
            ? column.typeConverter!.mapsToNullableDart(column.nullable)
            : column.nullable;

        if (nullableDartType) {
          return 'this.${column.nameInDart}';
        } else {
          return 'required this.${column.nameInDart}';
        }
      }).join(', '))
      ..write('});');

    if (isInsertable) {
      // If we generate mixins for the `toColumns` override, we don't need to
      // generate a duplicate method in the data class.
      if (!scope.options.writeToColumnsMixins) {
        _emitter.writeToColumnsOverride(columns);
      }
      if (scope.options.dataClassToCompanions &&
          scope.generationOptions.writeCompanions) {
        _writeToCompanion();
      }
    }

    // And a serializer and deserializer method
    _writeFromJson();
    _writeToJson();

    // And convenience methods to copy data from this class.
    _writeCopyWith();
    if (isInsertable &&
        scope.generationOptions.writeCompanions &&
        !columns.any((column) => column.isGenerated)) {
      _writeCopyWithCompanion();
    }

    _writeToString();
    _writeHashCode();

    overrideEquals(
      columns
          .map((c) => EqualityField(c.nameInDart, isList: c.isUint8ListInDart)),
      _emitter.dartCode(_emitter.writer.rowClass(table)),
      _emitter,
    );

    // finish class declaration
    _buffer.write('}');
  }

  void _writeFromJson() {
    final dataClassName = table.nameOfRowClass;

    _buffer
      ..write('factory $dataClassName.fromJson('
          'Map<String, dynamic> json, {$serializerType serializer}'
          ') {\n')
      ..write('serializer ??= ${_emitter.drift('driftRuntimeOptions')}'
          '.defaultSerializer;\n')
      ..write('return $dataClassName(');

    for (final column in columns) {
      final getter = column.nameInDart;
      final jsonKeyString = asDartLiteral(column.getJsonKey(scope.options));
      String deserialized;

      final typeConverter = column.typeConverter;
      if (typeConverter != null && typeConverter.alsoAppliesToJsonConversion) {
        var type =
            _emitter.dartCode(AnnotatedDartCode.type(typeConverter.jsonType!));
        if (column.nullable && typeConverter.canBeSkippedForNulls) {
          type = '$type?';
        }

        final fromConverter =
            "serializer.fromJson<$type>(json[$jsonKeyString])";
        final converterField = _converter(column);
        deserialized = '$converterField.fromJson($fromConverter)';
      } else {
        final type = _columnType(column);

        deserialized = "serializer.fromJson<$type>(json[$jsonKeyString])";
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
        'serializer ??= ${_emitter.drift('driftRuntimeOptions')}'
        '.defaultSerializer;\n'
        'return <String, dynamic>{\n');

    for (final column in columns) {
      final nameLiteral = asDartLiteral(column.getJsonKey(scope.options));
      final getter = column.nameInDart;
      final needsThis = getter == 'serializer';
      var value = needsThis ? 'this.$getter' : getter;
      var dartType = _columnType(column);

      final typeConverter = column.typeConverter;
      if (typeConverter != null && typeConverter.alsoAppliesToJsonConversion) {
        final converterField = _converter(column);
        value = '$converterField.toJson($value)';
        dartType = _jsonType(column);
      }

      _buffer.write("$nameLiteral: serializer.toJson<$dartType>($value),");
    }

    _buffer.write('};}');
  }

  void _writeCopyWith() {
    final dataClassName = _emitter.dartCode(_emitter.writer.rowClass(table));
    final wrapNullableInValue = scope.options.generateValuesInCopyWith;
    final valueType = _emitter.drift('Value');

    _buffer.write('$dataClassName copyWith({');
    for (var i = 0; i < columns.length; i++) {
      final column = columns[i];
      final last = i == columns.length - 1;
      final isNullable = column.nullableInDart;

      final typeName = _columnType(column);
      if (wrapNullableInValue && isNullable) {
        _buffer
          ..write('$valueType<$typeName> ${column.nameInDart} ')
          ..write('= const $valueType.absent()');
      } else if (!isNullable) {
        // We always use nullable parameters in copyWith, since all parameters
        // are optional. The !isNullable check is there to avoid a duplicate
        // question mark in the type name.
        _buffer.write('$typeName? ${column.nameInDart}');
      } else {
        _buffer.write('$typeName ${column.nameInDart}');
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
      final getter = column.nameInDart;

      if (wrapNullableInValue && column.nullableInDart) {
        _buffer
            .write('$getter: $getter.present ? $getter.value : this.$getter,');
      } else {
        _buffer.write('$getter: $getter ?? this.$getter,');
      }
    }

    _buffer.write(');');
  }

  void _writeCopyWithCompanion() {
    final asTable = table as DriftTable;
    final companionType = _emitter.writer.companionType(asTable);

    _emitter
      ..write('${table.nameOfRowClass} copyWithCompanion(')
      ..writeDart(companionType)
      ..writeln(' data) {')
      ..writeln('return ${table.nameOfRowClass}(');

    for (final column in columns) {
      // Generated columns do not appear in companions.
      assert(!column.isGenerated);
      final name = column.nameInDart;
      _buffer
          .write('$name: data.$name.present ? data.$name.value : this.$name,');
    }

    _buffer
      ..writeln(');')
      ..writeln('}');
  }

  void _writeToCompanion() {
    final asTable = table as DriftTable;
    final companionType = _emitter.writer.companionType(asTable);

    _emitter
      ..writeDart(companionType)
      ..writeln(' toCompanion(bool nullToAbsent) {')
      ..write('return ')
      ..writeDart(companionType)
      ..write('(');

    for (final column in columns) {
      // Generated columns are not parts of companions.
      if (column.isGenerated) continue;

      final dartName = column.nameInDart;
      _buffer
        ..write(dartName)
        ..write(': ');

      final needsNullCheck = column.nullableInDart;
      if (needsNullCheck) {
        _buffer
          ..write(dartName)
          ..write(' == null && nullToAbsent ? '
              'const ${_emitter.drift('Value')}.absent() : ');
        // We'll write the non-null case afterwards
      }

      _buffer
        ..write(_emitter.drift('Value'))
        ..write('(')
        ..write(dartName)
        ..write('),');
    }

    _buffer.writeln(');\n}');
  }

  void _writeToString() {
    overrideToString(
      table.nameOfRowClass,
      [for (final column in columns) column.nameInDart],
      _buffer,
    );
  }

  void _writeHashCode() {
    _buffer.write('@override\n int get hashCode => ');

    final fields = columns
        .map((c) => EqualityField(c.nameInDart, isList: c.isUint8ListInDart))
        .toList();
    writeHashCode(fields, _emitter);
    _buffer.write(';');
  }
}

/// Generates code mapping a row (represented as a `Map`) to positional and
/// named Dart arguments.
class RowMappingWriter {
  final List<DriftColumn> positional;
  final Map<DriftColumn, String> named;
  final DriftElementWithResultSet table;
  final Writer writer;

  /// Code to obtain an instance of a `DatabaseConnectionUser` in the generated
  /// code.
  ///
  /// This is used to lookup the connection options necessary for mapping values
  /// from SQL to Dart.
  final String databaseGetter;

  RowMappingWriter({
    required this.positional,
    required this.table,
    required this.writer,
    required this.databaseGetter,
    this.named = const {},
  });

  void writeArguments(StringBuffer buffer) {
    String readAndMap(DriftColumn column) {
      final columnName = column.nameInSql;
      final rawData = "data['\${effectivePrefix}$columnName']";

      final String sqlType;
      switch (column.sqlType) {
        case ColumnDriftType():
          sqlType = writer.drift(column.sqlType.builtin.toString());
        case ColumnCustomType(:final custom):
          sqlType = writer.dartCode(custom.expression);
      }

      var loadType = '$databaseGetter.typeMapping.read($sqlType, $rawData)';

      if (!column.nullable) {
        loadType += '!';
      }

      // run the loaded expression though the custom converter for the final
      // result.
      if (column.typeConverter != null) {
        // stored as a static field
        final code = writer.readConverter(column.typeConverter!,
            forNullable: column.nullable);
        final writtenCode = writer.dartCode(code);
        loadType = '$writtenCode.fromSql($loadType)';
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
      final getter = column.nameInDart;
      buffer.write('$getter: ${readAndMap(column)}, ');
    });

    buffer.write(')');
  }
}

extension WriteToColumns on TextEmitter {
  void writeToColumnsOverride(Iterable<DriftColumn> columns) {
    final expression = drift('Expression');

    this
      ..write('@override\nMap<String, $expression> toColumns'
          '(bool nullToAbsent) {\n')
      ..write('final map = <String, $expression> {};');

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
        write('if (!nullToAbsent || ${column.nameInDart} != null)');
      }
      if (needsScope) write('{');

      write('map[${asDartLiteral(column.nameInSql)}] = ');
      writeDart(
          wrapInVariable(column, AnnotatedDartCode.text(column.nameInDart)));
      writeln(';');

      // This one closes the optional if from before.
      if (needsScope) write('}');
    }

    write('return map; \n}\n');
  }
}
