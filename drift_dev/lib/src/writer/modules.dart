import 'package:build/build.dart';
import 'package:recase/recase.dart';

import '../analysis/custom_result_class.dart';
import '../analysis/driver/driver.dart';
import '../analysis/driver/state.dart';
import '../analysis/results/results.dart';
import 'queries/query_writer.dart';
import 'writer.dart';

/// Write a modular database accessor for a drift file.
///
/// In drift's (opt-in) modular build set, a `.drift.dart` file is generated for
/// each `.drift` file. This file defines elements defined in that drift file
/// (like tables, data classes, companions, fields for indexes and triggers).
///
/// If queries are defined in that drift file, a "modular accessor" is generated
/// as well. This accessor contains generated methods for all queries. The main
/// database will make these accessor available as getters.
class ModularAccessorWriter {
  final Scope scope;
  final FileState file;
  final DriftAnalysisDriver driver;

  ModularAccessorWriter(this.scope, this.file, this.driver);

  void write() {
    if (!file.needsModularAccessor(driver)) return;

    final className = scope.modularAccessor(file.ownUri);
    final generatedDatabase = scope.drift('GeneratedDatabase');

    scope.leaf()
      ..write('class $className extends ')
      ..write(_modular('ModularAccessor'))
      ..writeln('{ $className($generatedDatabase db): super(db);');

    final referencedElements = <DriftElement>{};

    var queries = file.fileAnalysis?.resolvedQueries ?? const {};

    final mappedQueries = transformCustomResultClasses(
      queries.values,
      (message) => log.warning('For accessor $className: $message'),
    );

    queries = queries.map((k, v) => MapEntry(k, mappedQueries[v] ?? v));

    for (final query in queries.entries) {
      final queryElement = file.analysis[query.key]?.result as DefinedSqlQuery?;
      if (queryElement != null) {
        referencedElements.addAll(queryElement.references);

        if (queryElement.mode != QueryMode.regular) {
          // Not a query for which a public API should exist
          continue;
        }
      }

      final value = query.value;
      if (value is SqlSelectQuery) {
        referencedElements.addAll(value.readsFromTables);
      }
      QueryWriter(scope.child()).write(value);
    }

    final restOfClass = scope.leaf();

    for (final reference in referencedElements) {
      // This element is referenced in a query, and the query writer expects it
      // to be available as a getter. So, let's generate that getter:

      if (reference is DriftElementWithResultSet) {
        final infoType = restOfClass.entityInfoType(reference);

        restOfClass
          ..writeDart(infoType)
          ..write(' get ${reference.dbGetterName} => ')
          ..writeDart(
              restOfClass.referenceElement(reference, 'attachedDatabase'))
          ..write(';');
      }
    }

    // Also make imports available
    final imports = file.discovery?.importDependencies ?? const [];
    for (final import in imports) {
      final file = driver.cache.knownFiles[import.uri];

      if (file != null && file.needsModularAccessor(driver)) {
        final moduleClass = restOfClass.modularAccessor(import.uri);
        final getterName = ReCase(moduleClass.toString()).camelCase;

        restOfClass
          ..writeDart(moduleClass)
          ..write(' get $getterName => this.accessor(')
          ..writeDart(moduleClass)
          ..writeln('.new);');
      }
    }

    restOfClass.writeln('}');
  }

  String _modular(String element) {
    return scope.refUri(modularSupport, element);
  }
}

extension WriteImplicitDaoGetter on Scope {
  void writeGetterForIncludedDriftFile(
      FileState import, DriftAnalysisDriver driver,
      {required bool isAccessor}) {
    assert(generationOptions.isModular);

    if (import.needsModularAccessor(driver)) {
      final type = modularAccessor(import.ownUri);
      final getter = ReCase(type.toString()).camelCase;

      final db = isAccessor ? 'attachedDatabase' : 'this';

      leaf()
        ..writeDart(type)
        ..write(' get $getter => ')
        ..writeUriRef(modularSupport, 'ReadDatabaseContainer')
        ..writeln('($db).accessor<')
        ..writeDart(type)
        ..write('>(')
        ..writeDart(type)
        ..writeln('.new);');
    }
  }
}
