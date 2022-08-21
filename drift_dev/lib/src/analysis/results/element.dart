import 'package:path/path.dart' show url;

class DriftElementId {
  final Uri libraryUri;
  final String name;

  DriftElementId(this.libraryUri, this.name);

  bool get isDefinedInDart => url.extension(libraryUri.path) == '.dart';
  bool get isDefinedInDrift => url.extension(libraryUri.path) == '.drift';
}

class DriftDeclaration {
  final Uri sourceUri;
  final int offset;

  DriftDeclaration(this.sourceUri, this.offset);
}

abstract class DriftElement {
  DriftElementId get id;
  DriftDeclaration get declaration;
}
