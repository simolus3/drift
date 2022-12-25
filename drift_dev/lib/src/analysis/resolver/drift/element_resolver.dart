import 'package:collection/collection.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/find_referenced_tables.dart';

import '../../backend.dart';
import '../../driver/error.dart';
import '../../driver/state.dart';
import '../../results/results.dart';
import '../resolver.dart';
import '../shared/dart_types.dart';
import 'sqlparser/drift_lints.dart';

abstract class DriftElementResolver<T extends DiscoveredElement>
    extends LocalElementResolver<T> {
  DriftElementResolver(
      super.file, super.discovered, super.resolver, super.state);

  void reportLints(AnalysisContext context, Iterable<DriftElement> references) {
    context.errors.forEach(reportLint);

    // Also run drift-specific lints on the query
    final linter = DriftSqlLinter(context, references: references)
      ..collectLints();
    linter.sqlParserErrors.forEach(reportLint);
  }

  Future<Element?> _findInDart(String identifier) async {
    final dartImports = file.discovery!.importDependencies
        .where((importUri) => importUri.path.endsWith('.dart'))
        // Also add `dart:core` as a default import so that types like `Record`
        // are available.
        .followedBy([AnnotatedDartCode.dartCore]);

    for (final import in dartImports) {
      LibraryElement library;
      try {
        library = await resolver.driver.backend.readDart(import);
      } on NotALibraryException {
        continue;
      }

      final foundElement = library.exportNamespace.get(identifier);
      if (foundElement != null) return foundElement;
    }

    return null;
  }

  Future<FoundDartClass?> findDartClass(String identifier) async {
    final foundElement = await _findInDart(identifier);
    if (foundElement is InterfaceElement) {
      return FoundDartClass(foundElement, null);
    } else if (foundElement is TypeAliasElement) {
      final innerType = foundElement.aliasedType;
      if (innerType is InterfaceType) {
        return FoundDartClass(innerType.element, innerType.typeArguments);
      }
    }

    return null;
  }

  /// Attempts to find a matching [ExistingRowClass] for a [DriftTableName]
  /// annotation.
  Future<ExistingRowClass?> resolveExistingRowClass(
      List<DriftColumn> columns, DriftTableName source) async {
    assert(source.useExistingDartClass);

    final dataClassName = source.overriddenDataClassName;
    final element = await _findInDart(dataClassName);
    FoundDartClass? foundDartClass;

    if (element is InterfaceElement) {
      foundDartClass = FoundDartClass(element, null);
    } else if (element is TypeAliasElement) {
      // Resolve type alias to a class, or use record if we have one.
      final innerType = element.aliasedType;
      if (innerType is InterfaceType) {
        foundDartClass =
            FoundDartClass(innerType.element, innerType.typeArguments);
      } else if (innerType is RecordType) {
        return validateRowClassFromRecordType(
          element,
          columns,
          innerType,
          false,
          this,
          await resolver.driver.loadKnownTypes(),
        );
      }
    }

    if (foundDartClass == null) {
      reportError(DriftAnalysisError.inDriftFile(
        source,
        'Existing Dart class $dataClassName was not found, are '
        'you missing an import?',
      ));
      return null;
    } else {
      final knownTypes = await resolver.driver.loadKnownTypes();
      return validateExistingClass(
          columns, foundDartClass, '', false, this, knownTypes);
    }
  }

  SqlEngine newEngineWithTables(Iterable<DriftElement> references) {
    return resolver.driver.typeMapping.newEngineWithTables(references);
  }

  DriftElement? findInResolved(List<DriftElement> references, String name) {
    return references.firstWhereOrNull((e) => e.id.sameName(name));
  }

  Future<List<DriftElement>> resolveSqlReferences(AstNode stmt) async {
    final references =
        resolver.driver.newSqlEngine().findReferencedSchemaTables(stmt);
    final found = <DriftElement>[];

    for (final table in references) {
      final result = await resolver.resolveReference(discovered.ownId, table);

      if (result is ResolvedReferenceFound) {
        found.add(result.element);
      } else {
        final referenceNode = stmt.allDescendants
            .firstWhere((e) => e is TableReference && e.tableName == table);

        reportErrorForUnresolvedReference(result,
            (msg) => DriftAnalysisError.inDriftFile(referenceNode, msg));
      }
    }

    return found;
  }

  void reportLint(AnalysisError parserError) {
    reportError(DriftAnalysisError.fromSqlError(parserError));
  }
}
