import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/state/options.dart';

class UpdateCompanionWriter {
  final SpecifiedTable table;
  final MoorOptions options;

  UpdateCompanionWriter(this.table, this.options);

  void writeInto(StringBuffer buffer) {
    buffer.write('class ${table.updateCompanionName} '
        'extends UpdateCompanion<${table.dartTypeName}> {\n');
    _writeFields(buffer);
    _writeConstructor(buffer);

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
}
