import 'package:meta/meta.dart';
import 'package:path/path.dart' show url;

import 'column.dart';

@sealed
class DriftElementId {
  final Uri libraryUri;
  final String name;

  DriftElementId(this.libraryUri, this.name);

  bool get isDefinedInDart => url.extension(libraryUri.path) == '.dart';
  bool get isDefinedInDrift => url.extension(libraryUri.path) == '.drift';

  bool sameName(String name) => this.name.toLowerCase() == name.toLowerCase();

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
  final DriftElementId id;
  final DriftDeclaration? declaration;

  Iterable<DriftElement> get references => const Iterable.empty();

  DriftElement(this.id, this.declaration);
}

abstract class DriftSchemaElement extends DriftElement {
  DriftSchemaElement(super.id, super.declaration);

  /// The exact, unaliased name of this element in the database's schema.
  String get schemaName => id.name;
}

abstract class DriftElementWithResultSet extends DriftSchemaElement {
  List<DriftColumn> get columns;

  DriftElementWithResultSet(super.id, super.declaration);
}
