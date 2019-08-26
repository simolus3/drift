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
