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

  String get _value => _emitter.drift('Value');

  late final List<DriftColumn> columns = [
    for (final column in table.columns)
      if (!column.isGenerated) column,
    // Expose the rowid column in the companion if there's no alias
    if (table.rowid?.isImplicitRowId == true) table.rowid!,
  ];

  UpdateCompanionWriter(this.table, this.scope) : _emitter = scope.leaf();

  String get _companionClass => _emitter.companionType(table).toString();
  String get _companionType => _emitter.dartCode(_emitter.companionType(table));

  String get _rowType => scope.generationOptions.writeDataClasses
      ? _emitter.dartCode(_emitter.rowType(table))
      : 'dynamic';

  void write() {
    _buffer.write('class $_companionClass '
        'extends '
        '${_emitter.drift('UpdateCompanion')}<$_rowType> {\n');
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
      _buffer.write('$modifier $_value<$type> ${column.nameInDart};\n');
    }
  }

  void _writeConstructor() {
    if (!scope.options.generateMutableClasses) {
      _buffer.write('const ');
    }
    _buffer.write('$_companionClass({');

    for (final column in columns) {
      _buffer.write('this.${column.nameInDart} = const $_value.absent(),');
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

      if (!column.isImplicitRowId && table.isColumnRequiredForInsert(column)) {
        requiredColumns.add(column);
        final typeName = _emitter.dartCode(_emitter.dartType(column));

        _buffer.write('required $typeName $param,');
      } else {
        _buffer.write('this.$param = const $_value.absent(),');
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
      _buffer.write('$param = $_value($param)');
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

    _buffer
      ..write(
          'static ${_emitter.drift('Insertable')}<$_rowType> $constructorName')
      ..write('({');

    final expression = _emitter.drift('Expression');
    for (final column in columns) {
      final typeName =
          _emitter.dartCode(_emitter.innerColumnType(column.sqlType));
      _buffer.write('$expression<$typeName>? ${column.nameInDart}, \n');
    }

    _buffer
      ..write('}) {\n')
      ..write('return ${_emitter.drift('RawValuesInsertable')}({');

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
      ..write(_companionType)
      ..write(' copyWith({');
    var first = true;
    for (final column in columns) {
      if (!first) {
        _buffer.write(', ');
      }
      first = false;

      final typeName = _emitter.dartCode(_emitter.dartType(column));
      _buffer.write('$_value<$typeName>? ${column.nameInDart}');
    }

    _buffer
      ..writeln('}) {')
      ..write('return $_companionType(');
    for (final column in columns) {
      final name = column.nameInDart;
      _buffer.write('$name: $name ?? this.$name,');
    }
    _buffer.write(');\n}\n');
  }

  void _writeToColumnsOverride() {
    final expression = _emitter.drift('Expression');
    _buffer
      ..write('@override\nMap<String, $expression> toColumns'
          '(bool nullToAbsent) {\n')
      ..write('final map = <String, $expression> {};');

    const locals = {'map', 'nullToAbsent', 'converter'};

    for (final column in columns) {
      final getterName = thisIfNeeded(column.nameInDart, locals);

      _buffer.writeln('if ($getterName.present) {');
      final typeName =
          _emitter.dartCode(_emitter.variableTypeCode(column, nullable: false));
      final mapSetter = 'map[${asDartLiteral(column.nameInSql)}] = '
          '${_emitter.drift('Variable')}<$typeName>';
      var value = '$getterName.value';

      final converter = column.typeConverter;
      if (converter != null) {
        // apply type converter before writing the variable
        final fieldName = _emitter.dartCode(
            _emitter.readConverter(converter, forNullable: column.nullable));
        _buffer.writeln('final converter = $fieldName;\n');
        value = 'converter.toSql($value)';
      }

      _buffer
        ..write(mapSetter)
        ..write('($value');

      if (column.sqlType.isCustom) {
        // Also specify the custom type since it can't be inferred from the
        // value passed to the variable.
        _buffer
          ..write(', ')
          ..write(_emitter.dartCode(column.sqlType.custom!.expression));
      }

      _buffer.writeln(');}');
    }

    _buffer.write('return map; \n}\n');
  }

  void _writeToString() {
    overrideToString(
      _emitter.companionType(table).toString(),
      [for (final column in columns) column.nameInDart],
      _buffer,
    );
  }

  /// Writes an extension on an existing row class to map an instance of that
  /// class to a suitable companion.
  void _writeToCompanionExtension() {
    final info = table.existingRowClass;
    if (info == null) return;

    final rowClass = _emitter.rowClass(table);
    final insertableClass = '_\$${rowClass}Insertable';

    _emitter
      // Class _$RowInsertable implements Insertable<RowClass> {
      ..write('class $insertableClass implements ')
      ..writeDriftRef('Insertable')
      ..write('<')
      ..writeDart(rowClass)
      ..writeln('> {')
      // Field to RowClass and constructor
      ..writeDart(rowClass)
      ..writeln(' _object;')
      ..writeln('$insertableClass(this._object);')
      // Map<String, Expression> toColumns(bool nullToAbsent) {
      ..writeln('@override')
      ..writeUriRef(AnnotatedDartCode.dartCore, 'Map')
      ..write('<')
      ..writeUriRef(AnnotatedDartCode.dartCore, 'String')
      ..write(', ')
      ..writeUriRef(AnnotatedDartCode.drift, 'Expression')
      ..write('> toColumns(')
      ..writeUriRef(AnnotatedDartCode.dartCore, 'bool')
      ..writeln(' nullToAbsent) {')
      ..writeln('return $_companionType(');

    final columns = info.positionalColumns.followedBy(info.namedColumns.values);
    for (final columnName in columns) {
      final column =
          table.columns.firstWhereOrNull((e) => e.nameInSql == columnName);

      if (column != null && !column.isGenerated) {
        final dartName = column.nameInDart;
        _emitter
          ..write('$dartName: ')
          ..writeDriftRef('Value')
          ..writeln('(_object.$dartName),');
      }
    }

    _emitter
      ..write(').toColumns(false);\n}\n}\n\n')
      ..write('extension ${rowClass}ToInsertable on ')
      ..writeDart(rowClass)
      ..writeln('{')
      ..write('$insertableClass toInsertable() {\n')
      ..write('return $insertableClass(this);\n')
      ..write('}\n}\n');
  }
}
