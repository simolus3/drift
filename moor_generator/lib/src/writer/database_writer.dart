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

    final entityGetters = <MoorSchemaEntity, String>{};

    for (final entity in db.entities) {
      final getterName = entity.dbGetterName;
      if (getterName != null) {
        entityGetters[entity] = entity.dbGetterName;
      }

      if (entity is MoorTable) {
        final tableClassName = entity.tableInfoName;

        writeMemoizedGetter(
          buffer: dbScope.leaf(),
          getterName: entity.dbGetterName,
          returnType: tableClassName,
          code: '$tableClassName(this)',
        );
      } else if (entity is MoorTrigger) {
        writeMemoizedGetter(
          buffer: dbScope.leaf(),
          getterName: entity.dbGetterName,
          returnType: 'Trigger',
          code: 'Trigger(${asDartLiteral(entity.create)}, '
              '${asDartLiteral(entity.displayName)})',
        );
      } else if (entity is MoorIndex) {
        writeMemoizedGetter(
          buffer: dbScope.leaf(),
          getterName: entity.dbGetterName,
          returnType: 'Index',
          code: 'Index(${asDartLiteral(entity.displayName)}, '
              '${asDartLiteral(entity.createStmt)})',
        );
      }
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

    schemaScope
      ..write(db.entities.map((e) {
        if (e is SpecialQuery) {
          return 'OnCreateQuery(${asDartLiteral(e.sql)})';
        }

        return entityGetters[e];
      }).join(', '))
      // close list literal, getter and finally the class
      ..write('];\n}');
  }
}
