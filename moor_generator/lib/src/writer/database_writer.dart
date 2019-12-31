import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/writer.dart';
import 'package:recase/recase.dart';

/// Generates the Dart code put into a `.g.dart` file when running the
/// generator.
class DatabaseWriter {
  final Database db;
  final Scope scope;

  DatabaseWriter(this.db, this.scope);

  void write() {
    // Write referenced tables
    for (final table in db.tables) {
      TableWriter(table, scope.child()).writeInto();
    }

    // Write the database class
    final dbScope = scope.child();

    final className = '_\$${db.fromClass.name}';
    final firstLeaf = dbScope.leaf();
    firstLeaf.write('abstract class $className extends GeneratedDatabase {\n'
        '$className(QueryExecutor e) : '
        'super(SqlTypeSystem.defaultInstance, e); \n');

    if (dbScope.options.generateConnectConstructor) {
      firstLeaf.write(
          '$className.connect(DatabaseConnection c): super.connect(c); \n');
    }

    final tableGetters = <MoorTable, String>{};

    for (final table in db.tables) {
      tableGetters[table] = table.tableFieldName;
      final tableClassName = table.tableInfoName;

      writeMemoizedGetter(
        buffer: dbScope.leaf(),
        getterName: table.tableFieldName,
        returnType: tableClassName,
        code: '$tableClassName(this)',
      );
    }

    // Write fields to access an dao. We use a lazy getter for that.
    for (final dao in db.daos) {
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
    for (final query in db.queries) {
      QueryWriter(query, dbScope.child(), writtenMappingMethods).write();
    }

    // Write List of tables
    final schemaScope = dbScope.leaf();
    schemaScope
      ..write('@override\nIterable<TableInfo> get allTables => ')
      ..write('allSchemaEntities.whereType<TableInfo>();\n')
      ..write('@override\nList<DatabaseSchemaEntity> get allSchemaEntities ')
      ..write('=> [');

    var first = true;
    for (final entity in db.entities) {
      if (!first) {
        schemaScope.write(', ');
      }

      if (entity is MoorTable) {
        schemaScope.write(tableGetters[entity]);
      } else if (entity is MoorTrigger) {
        schemaScope.write('Trigger(${asDartLiteral(entity.create)}, '
            '${asDartLiteral(entity.displayName)})');
      }
      first = false;
    }

    // finally, close bracket for the allSchemaEntities override and class.
    schemaScope.write('];\n}');
  }
}
