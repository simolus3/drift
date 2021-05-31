//@dart=2.9
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/src/writer/utils/override_toString.dart';
import 'package:moor_generator/writer.dart';

class UpdateCompanionWriter {
  final MoorTable table;
  final Scope scope;

  StringBuffer _buffer;

  UpdateCompanionWriter(this.table, this.scope) {
    _buffer = scope.leaf();
  }

  void write() {
    _buffer.write('class ${table.getNameForCompanionClass(scope.options)} '
        'extends UpdateCompanion<${table.dartTypeName}> {\n');
    _writeFields();

    _writeConstructor();
    _writeInsertConstructor();
    _writeCustomConstructor();

    _writeCopyWith();
    _writeToColumnsOverride();
    _writeFromRowClass();
    _writeRowClassToColumns();
    _writeToString();

    _buffer.write('}\n');
  }

  void _writeFields() {
    for (final column in table.columns) {
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

    for (final column in table.columns) {
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

    for (final column in table.columns) {
      final param = column.dartGetterName;

      if (table.isColumnRequiredForInsert(column)) {
        requiredColumns.add(column);
        final typeName = column.dartTypeCode(scope.generationOptions);

        _buffer.write('${scope.required} $typeName $param,');
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
    final constructorName = table.columns
            .map((e) => e.dartGetterName)
            .any((name) => name == 'custom')
        ? 'createCustom'
        : 'custom';

    _buffer
      ..write('static Insertable<${table.dartTypeName}> $constructorName')
      ..write('({');

    for (final column in table.columns) {
      final typeName = column.dartTypeCode(scope.generationOptions);
      final type = scope.nullableType('Expression<$typeName>');
      _buffer.write('$type ${column.dartGetterName}, \n');
    }

    _buffer..write('}) {\n')..write('return RawValuesInsertable({');

    for (final column in table.columns) {
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
    for (final column in table.columns) {
      if (!first) {
        _buffer.write(', ');
      }
      first = false;

      final typeName = column.dartTypeCode(scope.generationOptions);
      final valueType = scope.nullableType('Value<$typeName>');
      _buffer.write('$valueType ${column.dartGetterName}');
    }

    _buffer
      ..write('}) {\n') //
      ..write('return ${table.getNameForCompanionClass(scope.options)}(');
    for (final column in table.columns) {
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

    for (final column in table.columns) {
      final getterName = column.thisIfNeeded(locals);

      _buffer.write('if ($getterName.present) {');
      final typeName = column.variableTypeCode(scope.generationOptions);
      final mapSetter = 'map[${asDartLiteral(column.name.name)}] = '
          'Variable<$typeName>';

      if (column.typeConverter != null) {
        // apply type converter before writing the variable
        final converter = column.typeConverter;
        final fieldName = '${table.tableInfoName}.${converter.fieldName}';
        _buffer
          ..write('final converter = $fieldName;\n')
          ..write(mapSetter)
          ..write('(converter.mapToSql($getterName.value)');

        if (!column.nullable && scope.generationOptions.nnbd) {
          _buffer.write('!');
        }
        _buffer.write(');');
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

  void _writeFromRowClass() {
    final dataClassName = table.dartTypeName;

    _buffer
      ..write(table.getNameForCompanionClass(scope.options))
      ..write(' fromRowClass($dataClassName object, bool nullToAbsent) {\n');

    _buffer
      ..write('return ')
      ..write(table.getNameForCompanionClass(scope.options))
      ..write('(');

    for (final column in table.columns) {
      final dartName = column.dartGetterName;
      _buffer..write(dartName)..write(': ');

      if (column.mapRowClass) {
        final needsNullCheck = column.nullable || !scope.generationOptions.nnbd;
        if (needsNullCheck) {
          _buffer
            ..write("object.$dartName")
            ..write(' == null && nullToAbsent ? const Value.absent() : ');
          // We'll write the non-null case afterwards
        }

        _buffer..write('Value (')..write("object.$dartName")..write('),');
      } else {
        _buffer..write('Value.absent(),');
      }
    }

    _buffer.writeln(');\n}');
  }

  void _writeRowClassToColumns() {
    final dataClassName = table.dartTypeName;
    if (table.hasExistingRowClass) {
      _buffer
        ..write('Map<String, Expression> rowClassToColumns'
            '($dataClassName object, bool nullToAbsent) {\n')
        ..write('final map = <String, Expression> {};');

      for (final column in table.columns) {
        if (column.mapRowClass) {
          // We include all columns that are not null. If nullToAbsent is false, we
          // also include null columns. When generating NNBD code, we can include
          // non-nullable columns without an additional null check.
          final needsNullCheck = column.nullable || !scope.generationOptions.nnbd;
          final needsScope = needsNullCheck || column.typeConverter != null;
          if (needsNullCheck) {
            _buffer.write('if (!nullToAbsent || ${column.dartGetterName} != null)');
          }
          if (needsScope) _buffer.write('{');

          final typeName = column.variableTypeCode(scope.generationOptions);
          final mapSetter = 'map[${asDartLiteral(column.name.name)}] = '
              'Variable<$typeName>';

          if (column.typeConverter != null) {
            // apply type converter before writing the variable
            final converter = column.typeConverter;
            final fieldName = '${table.tableInfoName}.${converter.fieldName}';
            final assertNotNull = !column.nullable && scope.generationOptions.nnbd;

            _buffer
              ..write('final converter = $fieldName;\n')
              ..write(mapSetter)
              ..write('(converter.mapToSql(object.${column.dartGetterName})');
            if (assertNotNull) _buffer.write('!');
            _buffer.write(');');
          } else {
            // no type converter. Write variable directly
            _buffer
              ..write(mapSetter)
              ..write('(object.')
              ..write(column.dartGetterName)
              ..write(');');
          }

          // This one closes the optional if from before.
          if (needsScope) _buffer.write('}');
        }
      }

      _buffer.write('return map; \n}\n');
    }
  }

  void _writeToString() {
    overrideToString(
      table.getNameForCompanionClass(scope.options),
      [for (final column in table.columns) column.dartGetterName],
      _buffer,
    );
  }
}
