import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' show url;
import 'package:sqlparser/sqlparser.dart' hide AnalysisError;

import '../results/database.dart';
import '../results/element.dart';
import '../results/file_results.dart';
import '../results/query.dart';
import 'error.dart';

class FileState {
  final Uri ownUri;

  DiscoveredFileState? discovery;
  final List<DriftAnalysisError> errorsDuringDiscovery = [];

  final Map<DriftElementId, ElementAnalysisState> analysis = {};
  FileAnalysisResult? fileAnalysis;

  FileState(this.ownUri);

  String get extension => url.extension(ownUri.path);

  /// Whether this file contains a drift database or a drift accessor / DAO.
  bool get containsDatabaseAccessor {
    return analyzedElements.any((e) => e is BaseDriftAccessor);
  }

  /// Whether an accessor class making queries and imports available should be
  /// written for this file if modular analysis is enabled.
  bool get hasModularDriftAccessor {
    final hasImports = discovery?.importDependencies.isNotEmpty == true;
    final hasQuery = analyzedElements.any((e) => e is DefinedSqlQuery);

    return hasImports || hasQuery;
  }

  /// All analyzed [DriftElement]s found in this library.
  @visibleForTesting
  Iterable<DriftElement> get analyzedElements {
    return analysis.values.map((e) => e.result).whereType();
  }

  Iterable<DriftAnalysisError> get allErrors sync* {
    yield* errorsDuringDiscovery;

    for (final entry in analysis.values) {
      yield* entry.errorsDuringAnalysis;
    }

    final fileResults = fileAnalysis;
    if (fileResults != null) {
      yield* fileResults.analysisErrors;
    }
  }

  bool get isFullyAnalyzed {
    return discovery != null &&
        discovery!.locallyDefinedElements
            .every((e) => elementIsAnalyzed(e.ownId));
  }

  DriftElementId id(String name) => DriftElementId(ownUri, name);

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

class UnknownFile extends DiscoveredFileState {
  UnknownFile() : super(const []);
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
