import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/options.dart';

class UpdateCompanionWriter {
  final SpecifiedTable table;
  final MoorOptions options;

  UpdateCompanionWriter(this.table, this.options);

  void writeInto(StringBuffer buffer) {
    buffer.write('class ${table.updateCompanionName} '
        'implements UpdateCompanion<${table.dartTypeName}> {\n');
    _writeFields(buffer);
    _writeConstructor(buffer);
    _writeIsPresentOverride(buffer);

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

  void _writeIsPresentOverride(StringBuffer buffer) {
    buffer
      ..write('@override\nbool isValuePresent(int index, bool _) {\n')
      ..write('switch (index) {');

    for (var i = 0; i < table.columns.length; i++) {
      final getterName = table.columns[i].dartGetterName;
      buffer.write('case $i: return $getterName.present;\n');
    }

    buffer
      ..write('default: throw ArgumentError('
          "'Hit an invalid state while serializing data. Did you run the build "
          "step?');")
      ..write('};}\n');
  }
}
