import 'package:moor_generator/src/model/specified_db_classes.dart';
import 'package:moor_generator/src/model/specified_entities.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/src/writer/queries/query_writer.dart';
import 'package:moor_generator/src/writer/tables/table_writer.dart';
import 'package:moor_generator/src/writer/utils/memoized_getter.dart';
import 'package:moor_generator/src/writer/writer.dart';
import 'package:recase/recase.dart';

class DatabaseWriter {
  final SpecifiedDatabase db;
  final Scope scope;

  DatabaseWriter(this.db, this.scope);

  void write() {
    // Write referenced tables
    for (final table in db.allTables) {
      TableWriter(table, scope.child()).writeInto();
    }

    // Write the database class
    final dbScope = scope.child();

    final className = '_\$${db.fromClass.name}';
    dbScope.leaf().write(
        'abstract class $className extends GeneratedDatabase {\n'
        '$className(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e); \n');

    final tableGetters = <String>[];
    final entityGetters = <String>[];

    for (var table in db.allTables) {
      tableGetters.add(table.tableFieldName);
      final tableClassName = table.tableInfoName;

      writeMemoizedGetter(
        buffer: dbScope.leaf(),
        getterName: table.tableFieldName,
        returnType: tableClassName,
        code: '$tableClassName(this)',
      );
    }
    entityGetters.addAll(tableGetters);

    for (var otherEntity in db.otherEntities) {
      entityGetters.add(otherEntity.dartFieldName);

      if (otherEntity is SpecifiedTrigger) {
        writeMemoizedGetter(
          buffer: dbScope.leaf(),
          getterName: otherEntity.dartFieldName,
          returnType: 'Trigger',
          code: 'Trigger(${asDartLiteral(otherEntity.sql)}, '
              '${asDartLiteral(otherEntity.name)})',
        );
      }
    }

    // Write fields to access an dao. We use a lazy getter for that.
    for (var dao in db.daos) {
      final typeName = dao.displayName;
      final getterName = ReCase(typeName).camelCase;
      final databaseImplName = db.fromClass.name;

      writeMemoizedGetter(
        buffer: dbScope.leaf(),
        getterName: getterName,
        returnType: typeName,
        code: '$typeName(this as $databaseImplName)',
      );
    }

    // Write implementation for query methods
    final writtenMappingMethods = <String>{};
    for (var query in db.resolvedQueries) {
      QueryWriter(query, dbScope.child(), writtenMappingMethods).write();
    }

    // Write List of tables, close bracket for class
    dbScope.leaf()
      ..write('@override\nList<TableInfo> get allTables => [')
      ..write(tableGetters.join(','))
      ..write('];\n')
      ..write('@override\nList<DatabaseSchemaEntity> get allEntities => [')
      ..write(entityGetters.join(','))
      ..write('];\n}');
  }
}
