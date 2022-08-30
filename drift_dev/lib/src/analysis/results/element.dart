import 'package:meta/meta.dart';
import 'package:path/path.dart' show url;

@sealed
class DriftElementId {
  final Uri libraryUri;
  final String name;

  DriftElementId(this.libraryUri, this.name);

  bool get isDefinedInDart => url.extension(libraryUri.path) == '.dart';
  bool get isDefinedInDrift => url.extension(libraryUri.path) == '.drift';

  @override
  int get hashCode => Object.hash(DriftElementId, libraryUri, name);

  @override
  bool operator ==(Object other) {
    return other is DriftElementId &&
        other.libraryUri == libraryUri &&
        other.name == name;
  }

  @override
  String toString() {
    return 'DriftElementId($libraryUri, $name)';
  }
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
