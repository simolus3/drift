import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:drift_riverpod/drift_riverpod.dart';

final class KnownElements {
  /// The `ProviderListenable` type from riverpod.
  final InterfaceElement providerListenable;

  KnownElements({
    required this.providerListenable,
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
    );
  }
}

extension ParseConstant on DartObject {
  QueryProvider readQueryProvider() {
    return QueryProvider(
      singleRow: getField('singleRow')!.toBoolValue()!,
    );
  }
}
