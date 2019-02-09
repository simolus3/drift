import 'package:recase/recase.dart';
import 'package:sally_generator/src/model/specified_database.dart';
import 'package:sally_generator/src/writer/table_writer.dart';

class DatabaseWriter {

  final SpecifiedDatabase db;

  DatabaseWriter(this.db);

  void write(StringBuffer buffer) {
    for (final table in db.tables) {
      TableWriter(table).writeInto(buffer);
    }

    // Write the database class
    final className = '_\$${db.fromClass.name}';
    buffer.write('abstract class $className extends GeneratedDatabase {\n'
      '$className() : super(const SqlTypeSystem.withDefaults(), null); \n');

    for (var table in db.tables) {
      final tableFieldName = ReCase(table.fromClass.name).camelCase;
      final tableClassName = table.tableInfoName;

      buffer.write('$tableClassName get $tableFieldName => $tableClassName(this);');
    }

    buffer.write('}');
  }
}