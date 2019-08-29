import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/state/session.dart';

class UpdateCompanionWriter {
  final SpecifiedTable table;
  final GeneratorSession session;

  UpdateCompanionWriter(this.table, this.session);

  void writeInto(StringBuffer buffer) {
    buffer.write('class ${table.updateCompanionName} '
        'extends UpdateCompanion<${table.dartTypeName}> {\n');
    _writeFields(buffer);
    _writeConstructor(buffer);
    _writeInsertConstructor(buffer);
    _writeCopyWith(buffer);

    buffer.write('}\n');
  }

  void _writeFields(StringBuffer buffer) {
    for (var column in table.columns) {
      buffer.write('final Value<${column.dartTypeName}>'
          ' ${column.dartGetterName};\n');
    }
  }

  void _writeConstructor(StringBuffer buffer) {
    buffer.write('const ${table.updateCompanionName}({');

    for (var column in table.columns) {
      buffer.write('this.${column.dartGetterName} = const Value.absent(),');
    }

    buffer.write('});\n');
  }

  /// Writes a special `.insert` constructor. All columns which may not be
  /// absent during insert are marked `@required` here. Also, we don't need to
  /// use value wrappers here - `Value.absent` simply isn't an option.
  void _writeInsertConstructor(StringBuffer buffer) {
    final requiredColumns = <SpecifiedColumn>{};

    // can't be constant because we use initializers (this.a = Value(a)).
    // for a parameter a which is only potentially constant.
    buffer.write('${table.updateCompanionName}.insert({');

    // Say we had two required columns a and c, and an optional column b.
    // .insert({
    //    @required String a,
    //    this.b = const Value.absent(),
    //    @required String b}): a = Value(a), b = Value(b);
    // We don't need to use this. for the initializers, Dart figures that out.

    for (var column in table.columns) {
      final param = column.dartGetterName;

      if (column.requiredDuringInsert) {
        requiredColumns.add(column);

        buffer.write('@required ${column.dartTypeName} $param,');
      } else {
        buffer.write('this.$param = const Value.absent(),');
      }
    }
    buffer.write('})');

    var first = true;
    for (var required in requiredColumns) {
      if (first) {
        buffer.write(': ');
        first = false;
      } else {
        buffer.write(', ');
      }

      final param = required.dartGetterName;
      buffer.write('$param = Value($param)');
    }

    buffer.write(';\n');
  }

  void _writeCopyWith(StringBuffer buffer) {
    buffer.write('${table.updateCompanionName} copyWith({');
    var first = true;
    for (var column in table.columns) {
      if (!first) {
        buffer.write(', ');
      }
      first = false;
      buffer.write('Value<${column.dartTypeName}> ${column.dartGetterName}');
    }

    buffer
      ..write('}) {\n') //
      ..write('return ${table.updateCompanionName}(');
    for (var column in table.columns) {
      final name = column.dartGetterName;
      buffer.write('$name: $name ?? this.$name,');
    }
    buffer.write(');\n}\n');
  }
}
