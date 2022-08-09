import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/src/analyzer/runner/steps.dart';
import 'package:drift_dev/src/backends/backend.dart';
import 'package:sqlparser/sqlparser.dart';

import '../custom_row_class.dart';

/// Resolves a Dart class or generalized typedef pointing towards a Dart class.
Future<FoundDartClass?> findDartClass(
    Step step, List<ImportStatement> imports, String identifier) async {
  final dartImports = imports
      .map((import) => import.importedFile)
      .where((importUri) => importUri.endsWith('.dart'));

  for (final import in dartImports) {
    final resolved = step.task.session.resolve(step.file, import);
    LibraryElement library;
    try {
      library = await step.task.backend.resolveDart(resolved!.uri);
    } on NotALibraryException {
      continue;
    }

    final foundElement = library.exportNamespace.get(identifier);
    if (foundElement is ClassElement) {
      return FoundDartClass(foundElement, null);
    } else if (foundElement is TypeAliasElement) {
      final innerType = foundElement.aliasedType;
      if (innerType is InterfaceType) {
        return FoundDartClass(innerType.element2, innerType.typeArguments);
      }
    }
  }

  return null;
}
