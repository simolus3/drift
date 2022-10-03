import 'package:collection/collection.dart';

import '../../analysis/results/results.dart';
import '../../utils/string_escaper.dart';
import '../utils/override_toString.dart';
import '../writer.dart';

class UpdateCompanionWriter {
  final DriftTable table;
  final Scope scope;

  final TextEmitter _emitter;

  StringBuffer get _buffer => _emitter.buffer;

  late final List<DriftColumn> columns = [
    for (final column in table.columns)
      if (!column.isGenerated) column,
  ];

  UpdateCompanionWriter(this.table, this.scope) : _emitter = scope.leaf();

  String get _companionClass =>
      _emitter.dartCode(_emitter.companionType(table));

  void write() {
    final rowClass = _emitter.dartCode(_emitter.rowType(table));

    _buffer.write('class $_companionClass '
        'extends '
        'UpdateCompanion<$rowClass> {\n');
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
      final type = _emitter.dartCode(scope.writer.dartType(column));
      _buffer.write('$modifier Value<$type> ${column.nameInDart};\n');
    }
  }

  void _writeConstructor() {
    if (!scope.options.generateMutableClasses) {
      _buffer.write('const ');
    }
    _buffer.write('$_companionClass({');

    for (final column in columns) {
      _buffer.write('this.${column.nameInDart} = const Value.absent(),');
    }

    _buffer.write('});\n');
  }

  /// Writes a special `.insert` constructor. All columns which may not be
  /// absent during insert are marked `@required` here. Also, we don't need to
  /// use value wrappers here - `Value.absent` simply isn't an option.
  void _writeInsertConstructor() {
    final requiredColumns = <DriftColumn>{};

    // can't be constant because we use initializers (this.a = Value(a)).
    // for a parameter a which is only potentially constant.
    _buffer.write('$_companionClass.insert({');

    // Say we had two required columns a and c, and an optional column b.
    // .insert({
    //    @required String a,
    //    this.b = const Value.absent(),
    //    @required String b}): a = Value(a), b = Value(b);
    // We don't need to use this. for the initializers, Dart figures that out.

    for (final column in columns) {
      final param = column.nameInDart;

      if (table.isColumnRequiredForInsert(column)) {
        requiredColumns.add(column);
        final typeName = _emitter.dartCode(_emitter.dartType(column));

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

      final param = required.nameInDart;
      _buffer.write('$param = Value($param)');
    }

    _buffer.write(';\n');
  }

  void _writeCustomConstructor() {
    // Prefer a .custom constructor, unless there already is a field called
    // "custom", in which case we'll use createCustom
    final constructorName =
        columns.map((e) => e.nameInDart).any((name) => name == 'custom')
            ? 'createCustom'
            : 'custom';

    final rowType = _emitter.dartCode(_emitter.rowType(table));
    _buffer
      ..write('static Insertable<$rowType> $constructorName')
      ..write('({');

    for (final column in columns) {
      final typeName = column.innerColumnType();
      _buffer.write('Expression<$typeName>? ${column.nameInDart}, \n');
    }

    _buffer
      ..write('}) {\n')
      ..write('return RawValuesInsertable({');

    for (final column in columns) {
      _buffer
        ..write('if (${column.nameInDart} != null)')
        ..write(asDartLiteral(column.nameInSql))
        ..write(': ${column.nameInDart},');
    }

    _buffer.write('});\n}');
  }

  void _writeCopyWith() {
    _buffer
      ..write(_companionClass)
      ..write(' copyWith({');
    var first = true;
    for (final column in columns) {
      if (!first) {
        _buffer.write(', ');
      }
      first = false;

      final typeName = _emitter.dartCode(_emitter.dartType(column));
      _buffer.write('Value<$typeName>? ${column.nameInDart}');
    }

    _buffer
      ..writeln('}) {')
      ..write('return $_companionClass(');
    for (final column in columns) {
      final name = column.nameInDart;
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
      final getterName = thisIfNeeded(column.nameInDart, locals);

      _buffer.write('if ($getterName.present) {');
      final typeName = column.variableTypeCode(nullable: false);
      final mapSetter = 'map[${asDartLiteral(column.nameInSql)}] = '
          'Variable<$typeName>';

      final converter = column.typeConverter;
      if (converter != null) {
        // apply type converter before writing the variable
        final fieldName = _emitter.dartCode(
            _emitter.readConverter(converter, forNullable: column.nullable));
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
      _emitter.dartCode(_emitter.companionType(table)),
      [for (final column in columns) column.nameInDart],
      _buffer,
    );
  }

  /// Writes an extension on an existing row class to map an instance of that
  /// class to a suitable companion.
  void _writeToCompanionExtension() {
    final info = table.existingRowClass;
    if (info == null) return;

    final rowClass = _emitter.rowClass(table).toString();
    final rowType = _emitter.dartCode(_emitter.rowType(table));
    final insertableClass = '_\$${rowClass}Insertable';

    _buffer.write('class $insertableClass implements '
        'Insertable<$rowType> {\n'
        '$rowType _object;\n\n'
        '$insertableClass(this._object);\n\n'
        '@override\n'
        'Map<String, Expression> toColumns(bool nullToAbsent) {\n'
        'return $_companionClass(\n');

    final fields = info.positionalColumns.followedBy(info.namedColumns.keys);
    for (final field in fields) {
      final column =
          table.columns.firstWhereOrNull((e) => e.nameInDart == field);

      if (column != null && !column.isGenerated) {
        final dartName = column.nameInDart;
        _buffer.write('$dartName: Value (_object.$dartName),\n');
      }
    }

    _buffer
      ..write(').toColumns(false);\n}\n}\n\n')
      ..write('extension ${rowClass}ToInsertable '
          'on $rowType {')
      ..write('$insertableClass toInsertable() {\n')
      ..write('return $insertableClass(this);\n')
      ..write('}\n}\n');
  }
}
