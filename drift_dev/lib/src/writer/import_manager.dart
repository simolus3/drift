import 'package:path/path.dart' show url;

import '../utils/string_escaper.dart';
import 'writer.dart';

abstract class ImportManager {
  String? prefixFor(Uri definitionUri, String elementName);
}

class ImportManagerForPartFiles extends ImportManager {
  @override
  String? prefixFor(Uri definitionUri, String elementName) {
    return null; // todo: Find import alias from existing imports?
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
