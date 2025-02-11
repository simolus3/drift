import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';

final class KnownElements {
  /// The `ProviderListenable` type from riverpod.
  final InterfaceElement providerListenable;

  /// The `DatabaseConnectionUser` type from drift.
  final InterfaceElement databaseConnectionUser;

  KnownElements({
    required this.providerListenable,
    required this.databaseConnectionUser,
  });

  /// [element] must be defined in a library that imports `drift_riverpod`.
  static Future<KnownElements> read(Element element) async {
    final driftRiverpod = ((await element.session!
                .getLibraryByUri('package:drift_riverpod/drift_riverpod.dart'))
            as LibraryElementResult)
        .element;
    final namedImports = <String, Map<String, Element>>{
      for (final import in driftRiverpod.definingCompilationUnit.libraryImports)
        if (import.prefix case final prefix?)
          prefix.element.name: import.namespace.definedNames,
    };

    Element get(String namespace, String element) {
      return namedImports[namespace]!['$namespace.$element']!;
    }

    return KnownElements(
      providerListenable:
          get('riverpod', 'ProviderListenable') as InterfaceElement,
      databaseConnectionUser:
          get('drift', 'DatabaseConnectionUser') as InterfaceElement,
    );
  }
}
