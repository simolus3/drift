import 'package:drift/drift.dart' as drift;
// ignore: implementation_imports
import 'package:drift/src/runtime/executor/stream_queries.dart';
import 'package:drift_dev/src/writer/utils/memoized_getter.dart';
import 'package:recase/recase.dart';

import '../analysis/results/file_results.dart';
import '../analysis/results/results.dart';
import '../services/find_stream_update_rules.dart';
import '../utils/string_escaper.dart';
import 'modules.dart';
import 'queries/query_writer.dart';
import 'tables/table_writer.dart';
import 'tables/view_writer.dart';
import 'writer.dart';

/// Generates the Dart code put into a `.g.dart` file when running the
/// generator.
class DatabaseWriter {
  DatabaseGenerationInput input;
  final Scope scope;

  DriftDatabase get db => input.accessor;

  DatabaseWriter(this.input, this.scope);

  String get dbClassName {
    if (scope.generationOptions.isGeneratingForSchema) {
      return 'DatabaseAtV${scope.generationOptions.forSchema}';
    }

    final prefix = scope.generationOptions.isModular ? '' : r'_';

    return '$prefix\$${db.id.name}';
  }

  void write() {
    final elements = input.resolvedAccessor.availableElements;

    // Write data classes, companions and info classes
    if (!scope.generationOptions.isModular) {
      for (final reference in elements) {
        if (reference is DriftTable) {
          TableWriter(reference, scope.child()).writeInto();
        } else if (reference is DriftView) {
          ViewWriter(reference, scope.child(), this).write();
        }
      }
    }

    // Write the database class
    final dbScope = scope.child();

    final className = dbClassName;
    final firstLeaf = dbScope.leaf();
    final isAbstract = !scope.generationOptions.isGeneratingForSchema;
    if (isAbstract) {
      firstLeaf.write('abstract ');
    }

    firstLeaf
      ..write('class $className extends ')
      ..writeDriftRef('GeneratedDatabase')
      ..writeln('{')
      ..writeln('$className(${firstLeaf.drift('QueryExecutor e')}): super(e);');

    if (dbScope.options.generateConnectConstructor) {
      final conn = firstLeaf.drift('DatabaseConnection');
      firstLeaf.write('$className.connect($conn c): super.connect(c); \n');
    }

    final entityGetters = <DriftSchemaElement, String>{};

    for (final entity in elements.whereType<DriftSchemaElement>()) {
      final getterName = entity.dbGetterName;

      if (getterName != null) {
        // In the modular generation mode, table and view instances are still
        // created in the database instance. However, triggers and indices are
        // generated as a top-level field which is simply imported.
        if (scope.generationOptions.isModular &&
            (entity is DriftTrigger || entity is DriftIndex)) {
          final import = dbScope.generatedElement(entity, getterName);

          entityGetters[entity] = dbScope.dartCode(import);
          continue;
        }

        entityGetters[entity] = getterName;
      }

      if (entity is DriftTable) {
        final tableClassName = dbScope.dartCode(dbScope.entityInfoType(entity));

        writeMemoizedGetter(
          buffer: dbScope.leaf().buffer,
          getterName: entity.dbGetterName,
          returnType: tableClassName,
          code: '$tableClassName(this)',
        );
      } else if (entity is DriftTrigger) {
        writeMemoizedGetter(
          buffer: dbScope.leaf().buffer,
          getterName: entity.dbGetterName,
          returnType: 'Trigger',
          code: createTrigger(dbScope, entity),
        );
      } else if (entity is DriftIndex) {
        writeMemoizedGetter(
          buffer: dbScope.leaf().buffer,
          getterName: entity.dbGetterName,
          returnType: 'Index',
          code: createIndex(scope, entity),
        );
      } else if (entity is DriftView) {
        writeMemoizedGetter(
          buffer: dbScope.leaf().buffer,
          getterName: entity.dbGetterName,
          returnType: entity.entityInfoName,
          code: '${entity.entityInfoName}(this)',
        );
      }
    }

    // Write fields to access an dao. We use a lazy getter for that.
    for (final dao in db.accessors) {
      final typeName = firstLeaf.dartCode(dao.ownType);
      final getterName = ReCase(dao.ownType.toString()).camelCase;
      final databaseImplName = scope.dartCode(dao.databaseClass);

      writeMemoizedGetter(
        buffer: dbScope.leaf().buffer,
        getterName: getterName,
        returnType: typeName,
        code: '$typeName(this as $databaseImplName)',
      );
    }

    // Also write implicit DAOs for modular imports
    if (scope.generationOptions.isModular) {
      for (final import in input.resolvedAccessor.knownImports) {
        if (import.hasModularDriftAccessor) {
          final type = dbScope.modularAccessor(import.ownUri);
          final getter = ReCase(type.toString()).camelCase;

          dbScope.leaf()
            ..writeDart(type)
            ..write(' get $getter => ')
            ..writeUriRef(
                ModularAccessorWriter.modularSupport, 'ReadDatabaseContainer')
            ..writeln('(this).accessor<')
            ..writeDart(type)
            ..write('>(')
            ..writeDart(type)
            ..writeln('.new);');
        }
      }
    }

    // Write implementation for query methods
    for (final query in input.availableRegularQueries) {
      QueryWriter(dbScope.child()).write(query);
    }

    // Write List of tables
    final schemaScope = dbScope.leaf();

    final tableInfoType =
        '${dbScope.drift('TableInfo')}<${dbScope.drift('Table')}, Object?>';
    final schemaEntity = dbScope.drift('DatabaseSchemaEntity');

    schemaScope
      ..write('@override\nIterable<$tableInfoType> get allTables => ')
      ..write('allSchemaEntities.whereType<$tableInfoType>();\n')
      ..write('@override\nList<$schemaEntity> get allSchemaEntities ')
      ..write('=> [');

    schemaScope
      ..write(elements
          .map((e) {
            if (e is DefinedSqlQuery && e.mode == QueryMode.atCreate) {
              final resolved = input.importedQueries[e]!;
              final sql = schemaScope.sqlCode(resolved.root!);

              return 'OnCreateQuery(${asDartLiteral(sql)})';
            }

            return entityGetters[e];
          })
          .whereType<String>()
          .join(', '))
      // close list literal and allSchemaEntities getter
      ..write('];\n');

    final updateRules =
        FindStreamUpdateRules(input.resolvedAccessor).identifyRules();
    if (updateRules.rules.isNotEmpty) {
      schemaScope
        ..writeln('@override')
        ..writeDriftRef('StreamQueryUpdateRules')
        ..write(' get streamUpdateRules => const ')
        ..writeDriftRef('StreamQueryUpdateRules([');

      for (final rule in updateRules.rules) {
        rule.writeConstructor(schemaScope);
        schemaScope.write(', ');
      }

      schemaScope.writeln('],);');
    }

    if (scope.generationOptions.isGeneratingForSchema) {
      final version = scope.generationOptions.forSchema;

      schemaScope
        ..writeln('@override')
        ..writeln('int get schemaVersion => $version;');
    }

    if (scope.options.storeDateTimeValuesAsText) {
      // Override database options to reflect that DateTimes are stored as text.
      final options = schemaScope.drift('DriftDatabaseOptions');

      schemaScope
        ..writeln('@override')
        ..writeln('$options get options => '
            'const $options(storeDateTimeAsText: true);');
    }

    // close the class
    schemaScope.write('}\n');
  }

  static String createTrigger(Scope scope, DriftTrigger entity) {
    final sql = scope.sqlCode(entity.parsedStatement!);
    final trigger = scope.drift('Trigger');

    return '$trigger(${asDartLiteral(sql)}, ${asDartLiteral(entity.schemaName)})';
  }

  static String createIndex(Scope scope, DriftIndex entity) {
    final sql = scope.sqlCode(entity.parsedStatement!);
    final index = scope.drift('Index');

    return '$index(${asDartLiteral(entity.schemaName)}, ${asDartLiteral(sql)})';
  }
}

class GenerationInput<T extends BaseDriftAccessor> {
  final T accessor;
  final ResolvedDatabaseAccessor resolvedAccessor;
  final Map<DefinedSqlQuery, SqlQuery> importedQueries;

  GenerationInput(this.accessor, this.resolvedAccessor, this.importedQueries);

  /// All locally-defined and imported [SqlQuery] elements that are regular
  /// queries (so no query with [QueryMode.atCreate]).
  Iterable<SqlQuery> get availableRegularQueries {
    final imported = importedQueries.entries
        .where((entry) => entry.key.mode == QueryMode.regular)
        .map((e) => e.value);
    return resolvedAccessor.definedQueries.values.followedBy(imported);
  }
}

typedef DatabaseGenerationInput = GenerationInput<DriftDatabase>;
typedef AccessorGenerationInput = GenerationInput<DatabaseAccessor>;

extension on drift.UpdateRule {
  void writeConstructor(TextEmitter emitter) {
    if (this is drift.WritePropagation) {
      final write = this as drift.WritePropagation;

      emitter
        ..writeDriftRef('WritePropagation')
        ..write('(on: ');
      write.on.writeConstructor(emitter);
      emitter.write(', result: [');

      for (final update in write.result) {
        update.writeConstructor(emitter);
        emitter.write(', ');
      }

      emitter.write('],)');
    }
  }
}

extension on drift.TableUpdate {
  void writeConstructor(TextEmitter emitter) {
    emitter
      ..writeDriftRef('TableUpdate')
      ..write('(${asDartLiteral(table)}');

    if (kind == null) {
      emitter.write(')');
    } else {
      emitter.write(', kind: ');
      kind!.write(emitter);
      emitter.write(')');
    }
  }
}

extension on drift.TableUpdateQuery {
  void writeConstructor(TextEmitter emitter) {
    emitter.writeDriftRef('TableUpdateQuery');

    if (this is AnyUpdateQuery) {
      emitter.write('.any()');
    } else if (this is SpecificUpdateQuery) {
      final query = this as SpecificUpdateQuery;
      emitter.write('.onTableName(${asDartLiteral(query.table)} ');

      if (query.limitUpdateKind != null) {
        emitter.write(', limitUpdateKind: ');
        query.limitUpdateKind!.write(emitter);
      }
      emitter.write(')');
    } else if (this is MultipleUpdateQuery) {
      final queries = (this as MultipleUpdateQuery).queries;

      emitter.write('.allOf([');
      for (final query in queries) {
        query.writeConstructor(emitter);
        emitter.write(', ');
      }
      emitter.write('])');
    }
  }
}

extension on drift.UpdateKind {
  void write(TextEmitter emitter) {
    emitter
      ..writeDriftRef('UpdateKind')
      ..write('.$name');
  }
}
