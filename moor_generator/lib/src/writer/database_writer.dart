import 'package:moor/moor.dart';
// ignore: implementation_imports
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/services/find_stream_update_rules.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/src/utils/type_utils.dart';
import 'package:moor_generator/writer.dart';
import 'package:recase/recase.dart';

/// Generates the Dart code put into a `.g.dart` file when running the
/// generator.
class DatabaseWriter {
  final Database db;
  final Scope scope;

  DatabaseWriter(this.db, this.scope);

  String get _dbClassName {
    if (scope.generationOptions.isGeneratingForSchema) {
      return 'DatabaseAtV${scope.generationOptions.forSchema}';
    }

    return '_\$${db.fromClass.name}';
  }

  void write() {
    // Write referenced tables
    for (final table in db.tables) {
      TableWriter(table, scope.child()).writeInto();
    }

    // Write the database class
    final dbScope = scope.child();

    final className = _dbClassName;
    final firstLeaf = dbScope.leaf();
    final isAbstract = !scope.generationOptions.isGeneratingForSchema;
    if (isAbstract) {
      firstLeaf.write('abstract ');
    }

    firstLeaf.write('class $className extends GeneratedDatabase {\n'
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
          options: scope.generationOptions,
        );
      } else if (entity is MoorTrigger) {
        writeMemoizedGetter(
          buffer: dbScope.leaf(),
          getterName: entity.dbGetterName,
          returnType: 'Trigger',
          code: 'Trigger(${asDartLiteral(entity.createSql(scope.options))}, '
              '${asDartLiteral(entity.displayName)})',
          options: scope.generationOptions,
        );
      } else if (entity is MoorIndex) {
        writeMemoizedGetter(
          buffer: dbScope.leaf(),
          getterName: entity.dbGetterName,
          returnType: 'Index',
          code: 'Index(${asDartLiteral(entity.displayName)}, '
              '${asDartLiteral(entity.createSql(scope.options))})',
          options: scope.generationOptions,
        );
      }
    }

    // Write fields to access an dao. We use a lazy getter for that.
    for (final dao in db.daos) {
      final typeName = dao.codeString(scope.generationOptions);
      final getterName = ReCase(typeName).camelCase;
      final databaseImplName = db.fromClass.name;

      writeMemoizedGetter(
        buffer: dbScope.leaf(),
        getterName: getterName,
        returnType: typeName,
        code: '$typeName(this as $databaseImplName)',
        options: scope.generationOptions,
      );
    }

    // Write implementation for query methods
    for (final query in db.queries) {
      QueryWriter(query, dbScope.child()).write();
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
          final sql = e.formattedSql(scope.options);
          return 'OnCreateQuery(${asDartLiteral(sql)})';
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

    if (scope.generationOptions.isGeneratingForSchema) {
      final version = scope.generationOptions.forSchema;

      schemaScope
        ..writeln('@override')
        ..writeln('int get schemaVersion => $version;');
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
