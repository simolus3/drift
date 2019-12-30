import 'package:moor_generator/moor_generator.dart';
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

    final tableGetters = <String>[];

    for (final table in db.tables) {
      tableGetters.add(table.tableFieldName);
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

    // Write List of tables, close bracket for class
    dbScope.leaf()
      ..write('@override\nList<TableInfo> get allTables => [')
      ..write(tableGetters.join(','))
      ..write('];\n}');
  }
}
