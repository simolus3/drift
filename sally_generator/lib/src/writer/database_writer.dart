import 'package:recase/recase.dart';
import 'package:sally_generator/src/model/specified_database.dart';
import 'package:sally_generator/src/writer/table_writer.dart';

class DatabaseWriter {

  final SpecifiedDatabase db;

  DatabaseWriter(this.db);

  void write(StringBuffer buffer) {
    // Write referenced tables
    for (final table in db.tables) {
      TableWriter(table).writeInto(buffer);
    }

    // Write the database class
    final className = '_\$${db.fromClass.name}';
    buffer.write('abstract class $className extends GeneratedDatabase {\n'
      '$className() : super(const SqlTypeSystem.withDefaults(), null); \n');

    final tableGetters = <String>[];

    for (var table in db.tables) {
      final tableFieldName = ReCase(table.fromClass.name).camelCase;
      tableGetters.add(tableFieldName);
      final tableClassName = table.tableInfoName;

      buffer.write('$tableClassName get $tableFieldName => $tableClassName(this);');
    }

    // Write List of tables, close bracket for class
    buffer
      ..write('@override\nList<TableInfo> get allTables => [')
      ..write(tableGetters.join(','))
      ..write('];\n}');
  }
}