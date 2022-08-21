import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:path/path.dart' show url;

import 'results/element.dart';

class DriftAnalysisCache {
  final Map<Uri, FileState> knownFiles = {};
  final Map<DriftElementId, PendingDriftElement> knownElements = {};

  FileState notifyFileChanged(Uri uri) {
    // todo: Mark references for files that import this one as stale.
    // todo: Mark elements that reference an element in this file as stale.

    return knownFiles.putIfAbsent(uri, () => FileState(uri))
      ..errors.clear()
      ..kind = null
      ..parsedDartFile = null
      ..parsedDriftFile = null;
  }

  void notifyFileDeleted(Uri uri) {}
}

/// A [DriftElement] that is known to exist, but perhaps hasn't fully been
/// resolved yet.
class PendingDriftElement {
  final DriftElementId ownId;
  final List<Dependency> dependencies;

  bool cleanState = false;
  bool isOnCircularReferencePath = false;

  PendingDriftElement(this.ownId, List<Dependency> dependencies)
      : dependencies = UnmodifiableListView(dependencies);
}

abstract class Dependency {}

class ReferencesElement extends Dependency {
  final DriftElementId referencedElement;

  ReferencesElement(this.referencedElement);
}

class ReferencesUnknownElement extends Dependency {
  final String name;

  ReferencesUnknownElement(this.name);
}

enum FileKind {
  driftFile,
  dartLibrary,

  /// A Dart part file, a file with an unknown extension or a file that doesn't
  /// exist.
  invalid,
}

class FileState {
  final Uri uri;

  final List<DriftElementId> locallyDefinedElements = [];
  final List<Uri> directImports = [];
  final List<AnalysisError> errors = [];

  bool contentsFresh = false;
  bool referencesFresh = false;

  FileKind? kind;
  DriftFile? parsedDriftFile;
  LibraryElement? parsedDartFile;

  FileState(this.uri);

  String get extension => url.extension(uri.path);
}
