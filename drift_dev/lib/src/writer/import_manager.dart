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

class LibraryInputManager extends ImportManager {
  static final _dartCore = Uri.parse('dart:core');

  final Map<Uri, String> _importAliases = {};
  TextEmitter? emitter;

  LibraryInputManager();

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

      emitter?.writeln(
          'import ${asDartLiteral(definitionUri.toString())} as $alias;');
      return alias;
    });
  }
}
