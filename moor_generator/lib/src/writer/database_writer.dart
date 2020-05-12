import 'package:analyzer/dart/element/type.dart';
import 'package:moor/moor.dart';
// ignore: implementation_imports
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/services/find_stream_update_rules.dart';
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
    // Write generated convertesr
    final enumConverters =
        db.tables.expand((t) => t.converters).where((c) => c.isForEnum);
    final generatedConvertersForType = <DartType, String>{};
    var amountOfGeneratedConverters = 0;

    for (final converter in enumConverters) {
      String classForConverter;

      if (generatedConvertersForType.containsKey(converter.mappedType)) {
        classForConverter = generatedConvertersForType[converter.mappedType];
      } else {
        final id = amountOfGeneratedConverters++;
        classForConverter = '_\$GeneratedConverter\$$id';

        final buffer = scope.leaf();
        final dartType = converter.mappedType.getDisplayString();
        final superClass = converter.displayNameOfConverter;

        buffer
          ..writeln('class $classForConverter extends $superClass {')
          ..writeln('const $classForConverter();')
          ..writeln('@override')
          ..writeln('$dartType mapToDart(int fromDb) {')
          ..writeln('return fromDb == null ? null : $dartType.values[fromDb];')
          ..writeln('}')
          ..writeln('@override')
          ..writeln('int mapToSql($dartType value) {')
          ..writeln('return value?.index;')
          ..writeln('}')
          ..writeln('}');

        generatedConvertersForType[converter.mappedType] = classForConverter;
      }

      converter.expression = 'const $classForConverter()';
    }

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
      final typeName = dao.getDisplayString();
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
      // close list literal and allSchemaEntities getter
      ..write('];\n');

    final updateRules = FindStreamUpdateRules(db).identifyRules();
    if (updateRules.rules.isNotEmpty) {
      schemaScope
        ..write('@override\nStreamQueryUpdateRules get streamUpdateRules => ')
        ..write('const StreamQueryUpdateRules([');

      for (final rule in updateRules.rules) {
        rule.writeConstructor(schemaScope);
        schemaScope.write(', ');
      }

      schemaScope.write('],);\n');
    }

    // close the class
    schemaScope.write('}\n');
  }
}

const _kindToDartExpr = {
  UpdateKind.delete: 'UpdateKind.delete',
  UpdateKind.insert: 'UpdateKind.insert',
  UpdateKind.update: 'UpdateKind.update',
  null: 'null',
};

extension on UpdateRule {
  void writeConstructor(StringBuffer buffer) {
    if (this is WritePropagation) {
      final write = this as WritePropagation;

      buffer.write('WritePropagation(on: ');
      write.on.writeConstructor(buffer);
      buffer.write(', result: [');

      for (final update in write.result) {
        update.writeConstructor(buffer);
        buffer.write(', ');
      }

      buffer.write('],)');
    }
  }
}

extension on TableUpdate {
  void writeConstructor(StringBuffer buffer) {
    buffer.write(
        'TableUpdate(${asDartLiteral(table)}, kind: ${_kindToDartExpr[kind]})');
  }
}

extension on TableUpdateQuery {
  void writeConstructor(StringBuffer buffer) {
    if (this is AnyUpdateQuery) {
      buffer.write('TableUpdateQuery.any()');
    } else if (this is SpecificUpdateQuery) {
      final query = this as SpecificUpdateQuery;
      buffer
          .write('TableUpdateQuery.onTableName(${asDartLiteral(query.table)}, '
              'limitUpdateKind: ${_kindToDartExpr[query.limitUpdateKind]})');
    } else if (this is MultipleUpdateQuery) {
      final queries = (this as MultipleUpdateQuery).queries;

      buffer.write('TableUpdateQuery.allOf([');
      for (final query in queries) {
        query.writeConstructor(buffer);
        buffer.write(', ');
      }
      buffer.write('])');
    }
  }
}
