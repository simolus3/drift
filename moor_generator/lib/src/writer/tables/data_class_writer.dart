import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/writer.dart';
import 'package:recase/recase.dart';

class DataClassWriter {
  final MoorTable table;
  final Scope scope;

  StringBuffer _buffer;

  DataClassWriter(this.table, this.scope) {
    _buffer = scope.leaf();
  }

  void write() {
    _buffer.write('class ${table.dartTypeName} extends DataClass '
        'implements Insertable<${table.dartTypeName}> {\n');

    // write individual fields
    for (final column in table.columns) {
      _buffer
          .write('final ${column.dartTypeName} ${column.dartGetterName}; \n');
    }

	for (final variable in table.variables) {
      _buffer.write('$variable; \n');
    }

    // write constructor with named optional fields
    _buffer
      ..write(table.dartTypeName)
      ..write('({')
      ..write(table.columns.map((column) {
        if (column.nullable) {
          return 'this.${column.dartGetterName}';
        } else {
          return '@required this.${column.dartGetterName}';
        }
      }).join(', '))
      ..write('});');

    // Also write parsing factory
    _writeMappingConstructor();

    // And a serializer and deserializer method
    _writeFromJson();
    _writeToJson();
    _writeCompanionOverride();

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
      ..write('{String prefix}) {\n')
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
          'Map<String, dynamic> json, {ValueSerializer serializer}'
          ') {\n')
      ..write('serializer ??= moorRuntimeOptions.defaultSerializer;\n')
      ..write('return $dataClassName(');

    for (final column in table.columns) {
      final getter = column.dartGetterName;
      final jsonKey = column.getJsonKey(scope.options);
      final type = column.dartTypeName;

      _buffer.write("$getter: serializer.fromJson<$type>(json['$jsonKey']),");
    }

    _buffer.write(');}\n');

    if (scope.writer.options.generateFromJsonStringConstructor) {
      // also generate a constructor that only takes a json string
      _buffer.write('factory $dataClassName.fromJsonString(String encodedJson, '
          '{ValueSerializer serializer}) => '
          '$dataClassName.fromJson('
          'DataClass.parseJson(encodedJson) as Map<String, dynamic>, '
          'serializer: serializer);');
    }
  }

  void _writeToJson() {
    _buffer.write('@override Map<String, dynamic> toJson('
        '{ValueSerializer serializer}) {\n'
        'serializer ??= moorRuntimeOptions.defaultSerializer;\n'
        'return <String, dynamic>{\n');

    for (final column in table.columns) {
      final name = column.getJsonKey(scope.options);
      final getter = column.dartGetterName;
      final needsThis = getter == 'serializer';
      final value = needsThis ? 'this.$getter' : getter;

      _buffer
          .write("'$name': serializer.toJson<${column.dartTypeName}>($value),");
    }

    _buffer.write('};}');
  }

  void _writeCopyWith() {
    final dataClassName = table.dartTypeName;

    _buffer.write('$dataClassName copyWith({');
    for (var i = 0; i < table.columns.length; i++) {
      final column = table.columns[i];
      final last = i == table.columns.length - 1;

      _buffer.write('${column.dartTypeName} ${column.dartGetterName}');
      if (!last) {
        _buffer.write(',');
      }
    }

    _buffer.write('}) => $dataClassName(');

    for (final column in table.columns) {
      // we also have a method parameter called like the getter, so we can use
      // field: field ?? this.field
      final getter = column.dartGetterName;
      _buffer.write('$getter: $getter ?? this.$getter,');
    }

    _buffer.write(');');
  }

  void _writeToString() {
    /*
      @override
      String toString() {
        return (StringBuffer('User(')
            ..write('id: $id,')
            ..write('name: $name,')
            ..write('isAwesome: $isAwesome')
            ..write(')')).toString();
      }
     */

    _buffer
      ..write('@override\nString toString() {')
      ..write("return (StringBuffer('${table.dartTypeName}(')");

    for (var i = 0; i < table.columns.length; i++) {
      final column = table.columns[i];
      final getterName = column.dartGetterName;

      _buffer.write("..write('$getterName: \$$getterName");
      if (i != table.columns.length - 1) _buffer.write(', ');

      _buffer.write("')");
    }

    _buffer..write("..write(')')).toString();")..write('\}\n');
  }

  void _writeHashCode() {
    _buffer.write('@override\n int get hashCode => ');

    final fields = table.columns.map((c) => c.dartGetterName).toList();
    const HashCodeWriter().writeHashCode(fields, _buffer);
    _buffer.write(';');
  }

  void _writeCompanionOverride() {
    // TableCompanion createCompanion(bool nullToAbsent)

    final companionClass = table.getNameForCompanionClass(scope.options);
    _buffer.write('@override\n'
        '$companionClass createCompanion(bool nullToAbsent) {\n'
        'return $companionClass(');

    for (final column in table.columns) {
      final getter = column.dartGetterName;
      _buffer.write('$getter: $getter == null && nullToAbsent ? '
          'const Value.absent() : Value($getter),');
    }
    _buffer.write(');}\n');
  }
}
