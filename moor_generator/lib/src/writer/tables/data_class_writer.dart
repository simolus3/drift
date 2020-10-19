import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/src/writer/utils/override_toString.dart';
import 'package:moor_generator/writer.dart';
import 'package:recase/recase.dart';

class DataClassWriter {
  final MoorTable table;
  final Scope scope;

  StringBuffer _buffer;

  DataClassWriter(this.table, this.scope) {
    _buffer = scope.leaf();
  }

  String get serializerType => scope.nullableType('ValueSerializer');

  void write() {
    _buffer.write('class ${table.dartTypeName} extends DataClass '
        'implements Insertable<${table.dartTypeName}> {\n');

    // write individual fields
    for (final column in table.columns) {
      if (column.documentationComment != null) {
        _buffer.write('${column.documentationComment}\n');
      }
      final modifier = scope.options.fieldModifier;
      _buffer.write('$modifier ${column.dartTypeCode(scope.generationOptions)} '
          '${column.dartGetterName}; \n');
    }

    // write constructor with named optional fields
    _buffer
      ..write(table.dartTypeName)
      ..write('({')
      ..write(table.columns.map((column) {
        if (column.nullable) {
          return 'this.${column.dartGetterName}';
        } else {
          return '${scope.required} this.${column.dartGetterName}';
        }
      }).join(', '))
      ..write('});');

    // Also write parsing factory
    _writeMappingConstructor();

    _writeToColumnsOverride();
    if (scope.options.dataClassToCompanions) {
      _writeToCompanion();
    }

    // And a serializer and deserializer method
    _writeFromJson();
    _writeToJson();

    // And a convenience method to copy data from this class.
    _writeCopyWith();

    _writeToString();
    _writeHashCode();

    overrideEquals(table.columns.map((c) => c.dartGetterName),
        table.dartTypeName, _buffer);

    // finish class declaration
    _buffer.write('}');
  }

  void _writeMappingConstructor() {
    final dataClassName = table.dartTypeName;

    _buffer
      ..write('factory $dataClassName.fromData')
      ..write('(Map<String, dynamic> data, GeneratedDatabase db, ')
      ..write('{${scope.nullableType('String')} prefix}) { \n')
      ..write("final effectivePrefix = prefix ?? '';");

    final dartTypeToResolver = <String, String>{};

    final types = table.columns.map((c) => c.variableTypeName).toSet();
    for (final usedType in types) {
      // final intType = db.typeSystem.forDartType<int>();
      final resolver = '${ReCase(usedType).camelCase}Type';
      dartTypeToResolver[usedType] = resolver;

      _buffer
          .write('final $resolver = db.typeSystem.forDartType<$usedType>();\n');
    }

    // finally, the mighty constructor invocation:
    _buffer.write('return $dataClassName(');

    for (final column in table.columns) {
      // id: intType.mapFromDatabaseResponse(data["id])
      final getter = column.dartGetterName;
      final resolver = dartTypeToResolver[column.variableTypeName];
      final columnName = "'\${effectivePrefix}${column.name.name}'";

      var loadType = '$resolver.mapFromDatabaseResponse(data[$columnName])';

      // run the loaded expression though the custom converter for the final
      // result.
      if (column.typeConverter != null) {
        // stored as a static field
        final converter = column.typeConverter;
        final loaded = '${table.tableInfoName}.${converter.fieldName}';
        loadType = '$loaded.mapToDart($loadType)';
      }

      _buffer.write('$getter: $loadType,');
    }

    _buffer.write(');}\n');
  }

  void _writeFromJson() {
    final dataClassName = table.dartTypeName;

    _buffer
      ..write('factory $dataClassName.fromJson('
          'Map<String, dynamic> json, {$serializerType serializer}'
          ') {\n')
      ..write('serializer ??= moorRuntimeOptions.defaultSerializer;\n')
      ..write('return $dataClassName(');

    for (final column in table.columns) {
      final getter = column.dartGetterName;
      final jsonKey = column.getJsonKey(scope.options);
      final type = column.dartTypeCode(scope.generationOptions);

      _buffer.write("$getter: serializer.fromJson<$type>(json['$jsonKey']),");
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
        'serializer ??= moorRuntimeOptions.defaultSerializer;\n'
        'return <String, dynamic>{\n');

    for (final column in table.columns) {
      final name = column.getJsonKey(scope.options);
      final getter = column.dartGetterName;
      final needsThis = getter == 'serializer';
      final value = needsThis ? 'this.$getter' : getter;
      final dartType = column.dartTypeCode(scope.generationOptions);

      _buffer.write("'$name': serializer.toJson<$dartType>($value),");
    }

    _buffer.write('};}');
  }

  void _writeCopyWith() {
    final dataClassName = table.dartTypeName;
    final wrapNullableInValue = scope.options.generateValuesInCopyWith;

    _buffer.write('$dataClassName copyWith({');
    for (var i = 0; i < table.columns.length; i++) {
      final column = table.columns[i];
      final last = i == table.columns.length - 1;

      final typeName = column.dartTypeCode(scope.generationOptions);
      if (wrapNullableInValue && column.nullable) {
        _buffer
          ..write('Value<$typeName> ${column.dartGetterName} ')
          ..write('= const Value.absent()');
      } else if (!column.nullable && scope.generationOptions.nnbd) {
        // We always write nullable types in the copyWith constructor, since all
        // parameters are optional.
        _buffer.write('$typeName? ${column.dartGetterName}');
      } else {
        _buffer.write('$typeName ${column.dartGetterName}');
      }

      if (!last) {
        _buffer.write(',');
      }
    }

    _buffer.write('}) => $dataClassName(');

    for (final column in table.columns) {
      // We also have a method parameter called like the getter, so we can use
      // field: field ?? this.field. If we wrapped the parameter in a `Value`,
      // we can use field.present ? field.value : this.field
      final getter = column.dartGetterName;

      if (wrapNullableInValue && column.nullable) {
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

    for (final column in table.columns) {
      _buffer.write('if (!nullToAbsent || ${column.dartGetterName} != null) {');
      final mapSetter = 'map[${asDartLiteral(column.name.name)}] = '
          'Variable<${column.variableTypeName}>';

      if (column.typeConverter != null) {
        // apply type converter before writing the variable
        final converter = column.typeConverter;
        final fieldName = '${table.tableInfoName}.${converter.fieldName}';
        _buffer
          ..write('final converter = $fieldName;\n')
          ..write(mapSetter)
          ..write('(converter.mapToSql(${column.dartGetterName}));');
      } else {
        // no type converter. Write variable directly
        _buffer
          ..write(mapSetter)
          ..write('(')
          ..write(column.dartGetterName)
          ..write(');');
      }

      _buffer.write('}');
    }

    _buffer.write('return map; \n}\n');
  }

  void _writeToCompanion() {
    _buffer
      ..write(table.getNameForCompanionClass(scope.options))
      ..write(' toCompanion(bool nullToAbsent) {\n');

    _buffer
      ..write('return ')
      ..write(table.getNameForCompanionClass(scope.options))
      ..write('(');

    for (final column in table.columns) {
      final dartName = column.dartGetterName;
      _buffer
        ..write(dartName)
        ..write(': ')
        ..write(dartName)
        ..write(' == null && nullToAbsent ? const Value.absent() : Value (')
        ..write(dartName)
        ..write('),');
    }

    _buffer.writeln(');\n}');
  }

  void _writeToString() {
    overrideToString(
      table.dartTypeName,
      [for (final column in table.columns) column.dartGetterName],
      _buffer,
    );
  }

  void _writeHashCode() {
    _buffer.write('@override\n int get hashCode => ');

    final fields = table.columns.map((c) => c.dartGetterName).toList();
    const HashCodeWriter().writeHashCode(fields, _buffer);
    _buffer.write(';');
  }
}
