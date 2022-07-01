import 'package:collection/collection.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:drift_dev/src/writer/utils/override_toString.dart';
import 'package:drift_dev/writer.dart';

class UpdateCompanionWriter {
  final MoorTable table;
  final Scope scope;

  late StringBuffer _buffer;

  late final List<MoorColumn> columns = [
    for (final column in table.columns)
      if (!column.isGenerated) column,
  ];

  UpdateCompanionWriter(this.table, this.scope) {
    _buffer = scope.leaf();
  }

  void write() {
    _buffer.write('class ${table.getNameForCompanionClass(scope.options)} '
        'extends '
        'UpdateCompanion<${table.dartTypeCode(scope.generationOptions)}> {\n');
    _writeFields();

    _writeConstructor();
    _writeInsertConstructor();
    _writeCustomConstructor();

    _writeCopyWith();
    _writeToColumnsOverride();
    _writeToString();

    _buffer.write('}\n');

    if (table.existingRowClass?.generateInsertable ?? false) {
      _writeToCompanionExtension();
    }
  }

  void _writeFields() {
    for (final column in columns) {
      final modifier = scope.options.fieldModifier;
      final type = column.dartTypeCode(scope.generationOptions);
      _buffer.write('$modifier Value<$type> ${column.dartGetterName};\n');
    }
  }

  void _writeConstructor() {
    if (!scope.options.generateMutableClasses) {
      _buffer.write('const ');
    }
    _buffer.write('${table.getNameForCompanionClass(scope.options)}({');

    for (final column in columns) {
      _buffer.write('this.${column.dartGetterName} = const Value.absent(),');
    }

    _buffer.write('});\n');
  }

  /// Writes a special `.insert` constructor. All columns which may not be
  /// absent during insert are marked `@required` here. Also, we don't need to
  /// use value wrappers here - `Value.absent` simply isn't an option.
  void _writeInsertConstructor() {
    final requiredColumns = <MoorColumn>{};

    // can't be constant because we use initializers (this.a = Value(a)).
    // for a parameter a which is only potentially constant.
    _buffer.write('${table.getNameForCompanionClass(scope.options)}.insert({');

    // Say we had two required columns a and c, and an optional column b.
    // .insert({
    //    @required String a,
    //    this.b = const Value.absent(),
    //    @required String b}): a = Value(a), b = Value(b);
    // We don't need to use this. for the initializers, Dart figures that out.

    for (final column in columns) {
      final param = column.dartGetterName;

      if (table.isColumnRequiredForInsert(column)) {
        requiredColumns.add(column);
        final typeName = column.dartTypeCode(scope.generationOptions);

        _buffer.write('required $typeName $param,');
      } else {
        _buffer.write('this.$param = const Value.absent(),');
      }
    }
    _buffer.write('})');

    var first = true;
    for (final required in requiredColumns) {
      if (first) {
        _buffer.write(': ');
        first = false;
      } else {
        _buffer.write(', ');
      }

      final param = required.dartGetterName;
      _buffer.write('$param = Value($param)');
    }

    _buffer.write(';\n');
  }

  void _writeCustomConstructor() {
    // Prefer a .custom constructor, unless there already is a field called
    // "custom", in which case we'll use createCustom
    final constructorName =
        columns.map((e) => e.dartGetterName).any((name) => name == 'custom')
            ? 'createCustom'
            : 'custom';

    final dartTypeName = table.dartTypeCode(scope.generationOptions);
    _buffer
      ..write('static Insertable<$dartTypeName> $constructorName')
      ..write('({');

    for (final column in columns) {
      // todo (breaking change): This should not consider type converters.
      final typeName = column.dartTypeCode(scope.generationOptions);
      _buffer.write('Expression<$typeName>? ${column.dartGetterName}, \n');
    }

    _buffer
      ..write('}) {\n')
      ..write('return RawValuesInsertable({');

    for (final column in columns) {
      _buffer
        ..write('if (${column.dartGetterName} != null)')
        ..write(asDartLiteral(column.name.name))
        ..write(': ${column.dartGetterName},');
    }

    _buffer.write('});\n}');
  }

  void _writeCopyWith() {
    _buffer
      ..write(table.getNameForCompanionClass(scope.options))
      ..write(' copyWith({');
    var first = true;
    for (final column in columns) {
      if (!first) {
        _buffer.write(', ');
      }
      first = false;

      final typeName = column.dartTypeCode(scope.generationOptions);
      _buffer.write('Value<$typeName>? ${column.dartGetterName}');
    }

    _buffer
      ..write('}) {\n') //
      ..write('return ${table.getNameForCompanionClass(scope.options)}(');
    for (final column in columns) {
      final name = column.dartGetterName;
      _buffer.write('$name: $name ?? this.$name,');
    }
    _buffer.write(');\n}\n');
  }

  void _writeToColumnsOverride() {
    // Map<String, Variable> entityToSql(covariant UpdateCompanion<D> instance)
    _buffer
      ..write('@override\nMap<String, Expression> toColumns'
          '(bool nullToAbsent) {\n')
      ..write('final map = <String, Expression> {};');

    const locals = {'map', 'nullToAbsent', 'converter'};

    for (final column in columns) {
      final getterName = column.thisIfNeeded(locals);

      _buffer.write('if ($getterName.present) {');
      final typeName = column.variableTypeCode(scope.generationOptions);
      final mapSetter = 'map[${asDartLiteral(column.name.name)}] = '
          'Variable<$typeName>';

      final converter = column.typeConverter;
      if (converter != null) {
        // apply type converter before writing the variable
        final fieldName =
            converter.tableAndField(forNullableColumn: column.nullable);
        _buffer
          ..write('final converter = $fieldName;\n')
          ..write(mapSetter)
          ..write('(converter.toSql($getterName.value)')
          ..write(');');
      } else {
        // no type converter. Write variable directly
        _buffer
          ..write(mapSetter)
          ..write('(')
          ..write('$getterName.value')
          ..write(');');
      }

      _buffer.write('}');
    }

    _buffer.write('return map; \n}\n');
  }

  void _writeToString() {
    overrideToString(
      table.getNameForCompanionClass(scope.options),
      [for (final column in columns) column.dartGetterName],
      _buffer,
    );
  }

  void _writeToCompanionExtension() {
    final info = table.existingRowClass;
    if (info == null) return;

    final companionName = table.getNameForCompanionClass(scope.options);
    final className = table.dartTypeName;
    final insertableClass = '_\$${className}Insertable';

    _buffer.write('class $insertableClass implements '
        'Insertable<$className> {\n'
        '$className _object;\n\n'
        '$insertableClass(this._object);\n\n'
        '@override\n'
        'Map<String, Expression> toColumns(bool nullToAbsent) {\n'
        'return $companionName(\n');

    for (final field in info.mapping.values) {
      final column =
          table.columns.firstWhereOrNull((e) => e.dartGetterName == field.name);

      if (column != null && !column.isGenerated) {
        final dartName = column.dartGetterName;
        _buffer.write('$dartName: Value (_object.$dartName),\n');
      }
    }

    _buffer
      ..write(').toColumns(false);\n}\n}\n\n')
      ..write('extension ${table.dartTypeName}ToInsertable '
          'on ${table.dartTypeName} {')
      ..write('$insertableClass toInsertable() {\n')
      ..write('return _\$${className}Insertable(this);\n')
      ..write('}\n}\n');
  }
}
