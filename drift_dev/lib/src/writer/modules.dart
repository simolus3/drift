import 'package:path/path.dart' show url;
import 'package:recase/recase.dart';

import '../analysis/driver/state.dart';
import '../analysis/results/results.dart';
import '../utils/string_escaper.dart';
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

  ModularAccessorWriter(this.scope, this.file);

  void write() {
    if (!file.hasModularDriftAccessor) return;

    final className = scope.modularAccessor(file.ownUri);
    final generatedDatabase = scope.drift('GeneratedDatabase');

    scope.leaf()
      ..write('class $className extends ')
      ..write(_modular('ModularAccessor'))
      ..writeln('{ $className($generatedDatabase db): super(db);');

    final referencedElements = <DriftElement>{};

    final queries = file.fileAnalysis?.resolvedQueries ?? const {};
    for (final query in queries.entries) {
      final queryElement = file.analysis[query.key]?.result;
      if (queryElement != null) {
        referencedElements.addAll(queryElement.references);
      }

      QueryWriter(scope.child()).write(query.value);
    }

    final restOfClass = scope.leaf();

    for (final reference in referencedElements) {
      // This element is referenced in a query, and the query writer expects it
      // to be available as a getter. So, let's generate that getter:

      if (reference is DriftElementWithResultSet) {
        final infoType = restOfClass.entityInfoType(reference);

        restOfClass
          ..writeDart(infoType)
          ..write(' get ${reference.dbGetterName} => this.resultSet<')
          ..writeDart(infoType)
          ..write('>(${asDartLiteral(reference.schemaName)});');
      }
    }

    // Also make imports available
    final imports = file.discovery?.importDependencies ?? const [];
    for (final import in imports) {
      if (url.extension(import.path) == '.drift') {
        final moduleClass = restOfClass.modularAccessor(import);
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

  static final Uri modularSupport =
      Uri.parse('package:drift/internal/modular.dart');
}
