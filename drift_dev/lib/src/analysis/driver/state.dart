import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' show url;
import 'package:sqlparser/sqlparser.dart' hide AnalysisError;

import '../results/element.dart';
import 'error.dart';

class FileState {
  final Uri ownUri;

  DiscoveredFileState? discovery;
  final Map<DriftElementId, ElementAnalysisState> analysis = {};

  final List<DriftAnalysisError> errorsDuringDiscovery = [];

  FileState(this.ownUri);

  String get extension => url.extension(ownUri.path);

  bool elementIsAnalyzed(DriftElementId id) {
    return analysis[id]?.isUpToDate == true;
  }
}

abstract class DiscoveredFileState {
  final List<DiscoveredElement> locallyDefinedElements;

  bool get isValidImport => false;

  Iterable<Uri> get importDependencies => const [];

  DiscoveredFileState(this.locallyDefinedElements);
}

class DiscoveredDriftFile extends DiscoveredFileState {
  final String originalSource;
  final DriftFile ast;
  final List<DriftFileImport> imports;

  @override
  bool get isValidImport => true;

  @override
  Iterable<Uri> get importDependencies => imports.map((e) => e.importedUri);

  DiscoveredDriftFile({
    required this.originalSource,
    required this.ast,
    required this.imports,
    required List<DiscoveredElement> locallyDefinedElements,
  }) : super(locallyDefinedElements);
}

class DriftFileImport {
  final ImportStatement ast;
  final Uri importedUri;

  DriftFileImport(this.ast, this.importedUri);
}

class DiscoveredDartLibrary extends DiscoveredFileState {
  final LibraryElement library;

  @override
  bool get isValidImport => true;

  DiscoveredDartLibrary(this.library, super.locallyDefinedElements);
}

class NotADartLibrary extends DiscoveredFileState {
  NotADartLibrary() : super(const []);
}

class NoSuchFile extends DiscoveredFileState {
  NoSuchFile() : super(const []);
}

abstract class DiscoveredElement {
  final DriftElementId ownId;

  DiscoveredElement(this.ownId);

  @override
  String toString() {
    return '$runtimeType:$ownId';
  }
}

class ElementAnalysisState {
  final DriftElementId ownId;
  final List<DriftAnalysisError> errorsDuringAnalysis = [];

  DriftElement? result;

  bool isUpToDate = false;

  ElementAnalysisState(this.ownId);
}
