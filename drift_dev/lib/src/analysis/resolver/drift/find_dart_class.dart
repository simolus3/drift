import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../../backend.dart';
import '../resolver.dart';
import '../shared/dart_types.dart';

extension FindDartClass on LocalElementResolver {
  /// Resolves a Dart class or generalized typedef pointing towards a Dart class.
  Future<FoundDartClass?> findDartClass(
      List<Uri> imports, String identifier) async {
    final dartImports =
        imports.where((importUri) => importUri.path.endsWith('.dart'));

    for (final import in dartImports) {
      LibraryElement library;
      try {
        library = await resolver.driver.backend.readDart(import);
      } on NotALibraryException {
        continue;
      }

      final foundElement = library.exportNamespace.get(identifier);
      if (foundElement is InterfaceElement) {
        return FoundDartClass(foundElement, null);
      } else if (foundElement is TypeAliasElement) {
        final innerType = foundElement.aliasedType;
        if (innerType is InterfaceType) {
          return FoundDartClass(innerType.element, innerType.typeArguments);
        }
      }
    }

    return null;
  }
}
