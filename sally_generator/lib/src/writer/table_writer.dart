import 'package:sally_generator/src/model/specified_table.dart';

class TableWriter {
  final SpecifiedTable table;

  TableWriter(this.table);

  void writeInto(StringBuffer buffer) {
    writeDataClass(buffer);
  }

  void writeDataClass(StringBuffer buffer) {
    buffer.write('class ${table.dartTypeName} {\n');

    // write individual fields
    for (var column in table.columns) {
      buffer.write('final ${column.dartTypeName} ${column.dartGetterName}; \n');
    }

    // write constructor with named optional fields
    buffer
      ..write(table.dartTypeName)
      ..write('({')
      ..write(table.columns
          .map((column) => 'this.${column.dartGetterName}')
          .join(', '))
      ..write('});')
      ..write('\n}');
  }
}
