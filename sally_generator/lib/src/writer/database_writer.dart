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
        '$className(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e); \n');

    final tableGetters = <String>[];

    for (var table in db.tables) {
      final tableFieldName = ReCase(table.fromClass.name).camelCase;
      tableGetters.add(tableFieldName);
      final tableClassName = table.tableInfoName;

      buffer.write(
          '$tableClassName get $tableFieldName => $tableClassName(this);');
    }

    // Write fields to access an dao. We use a lazy getter:
    /*
        DaoType _daoName;
        DaoType get daoName => _daoName ??= DaoType(this);
     */
    for (var dao in db.daos) {
      final typeName = dao.displayName;
      final getterName = ReCase(typeName).camelCase;
      final fieldName = '_$getterName';

      buffer
        ..write('$typeName $fieldName;\n')
        ..write('$typeName get $getterName => $fieldName ??= $typeName(this);');
    }

    // Write List of tables, close bracket for class
    buffer
      ..write('@override\nList<TableInfo> get allTables => [')
      ..write(tableGetters.join(','))
      ..write('];\n}');
  }
}
