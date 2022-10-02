abstract class ImportManager {
  String? prefixFor(Uri definitionUri, String elementName);
}

class ImportManagerForPartFiles extends ImportManager {
  @override
  String? prefixFor(Uri definitionUri, String elementName) {
    return null; // todo: Find import alias from existing imports?
  }
}
