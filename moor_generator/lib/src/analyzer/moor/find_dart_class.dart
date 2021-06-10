// @dart=2.9
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/backends/backend.dart';
import 'package:sqlparser/sqlparser.dart';

Future<ClassElement> findDartClass(
    Step step, List<ImportStatement> imports, String identifier) async {
  final dartImports = imports
      .map((import) => import.importedFile)
      .where((importUri) => importUri.endsWith('.dart'));

  for (final import in dartImports) {
    final resolved = step.task.session.resolve(step.file, import);
    LibraryElement library;
    try {
      library = await step.task.backend.resolveDart(resolved.uri);
    } on NotALibraryException {
      continue;
    }

    final foundElement = library.exportNamespace.get(identifier);
    if (foundElement is ClassElement) {
      return foundElement;
    }
  }

  return null;
}
