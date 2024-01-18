import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' show url;

import '../utils/string_escaper.dart';
import 'writer.dart';

abstract class ImportManager {
  String? prefixFor(Uri definitionUri, String elementName);
}

class ImportManagerForPartFiles extends ImportManager {
  final LibraryElement mainLibrary;
  final Map<String, Map<String, Element>> _namedImports = {};

  ImportManagerForPartFiles(this.mainLibrary) {
    for (final import in mainLibrary.libraryImports) {
      if (import.prefix case ImportElementPrefix prefix) {
        // Not using import.namespace here because that contains the prefix
        // everywhere. We want to look up the prefix from the raw name.
        final library = import.importedLibrary;
        if (library != null) {
          _namedImports[prefix.element.name] =
              library.exportNamespace.definedNames;
        }
      }
    }
  }

  @override
  String? prefixFor(Uri definitionUri, String elementName) {
    // Part files can't add their own imports, so try to find the element in an
    // existing import.
    for (final MapEntry(:key, :value) in _namedImports.entries) {
      if (value.containsKey(elementName)) {
        return key;
      }
    }

    return null;
  }
}

class NullImportManager extends ImportManager {
  @override
  String? prefixFor(Uri definitionUri, String elementName) {
    return null;
  }
}

/// An [ImportManager] for generation contexts that create standalone Dart
/// libraries capable of managing their own imports.
class LibraryImportManager extends ImportManager {
  static final _dartCore = Uri.parse('dart:core');

  final Map<Uri, String> _importAliases = {};

  /// The uri of the file being generated.
  ///
  /// This allows constructing relative imports for assets that aren't in
  /// `lib/`.
  final Uri? _outputUri;

  TextEmitter? emitter;

  LibraryImportManager([this._outputUri]);

  void linkToWriter(Writer writer) {
    emitter = writer.leaf();
  }

  @override
  String? prefixFor(Uri definitionUri, String elementName) {
    if (definitionUri == _dartCore) {
      return null;
    }

    return _importAliases.putIfAbsent(definitionUri, () {
      final alias = 'i${_importAliases.length}';

      final importedScheme = definitionUri.scheme;
      String importLiteral;

      if (importedScheme != 'package' &&
          importedScheme != 'dart' &&
          importedScheme == _outputUri?.scheme) {
        // Not a package nor a dart import, use a relative import instead
        importLiteral = url.relative(definitionUri.path,
            from: url.dirname(_outputUri!.path));
      } else {
        importLiteral = definitionUri.toString();
      }

      emitter?.writeln('import ${asDartLiteral(importLiteral)} as $alias;');
      return alias;
    });
  }
}
