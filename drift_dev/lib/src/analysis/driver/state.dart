import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' show url;
import 'package:sqlparser/sqlparser.dart' hide AnalysisError;

import '../resolver/intermediate_state.dart';
import '../results/database.dart';
import '../results/element.dart';
import '../results/file_results.dart';
import '../results/query.dart';
import 'driver.dart';
import 'error.dart';

typedef DriftImport = ({Uri uri, bool transitive});

class FileState {
  final Uri ownUri;

  DiscoveredFileState? discovery;
  CachedDiscoveryResults? cachedDiscovery;

  final List<DriftAnalysisError> errorsDuringDiscovery = [];

  final Map<DriftElementId, ElementAnalysisState> analysis = {};
  FileAnalysisResult? fileAnalysis;

  bool? _needsModularAccessor;

  FileState(this.ownUri);

  bool get isValidImport {
    return (cachedDiscovery?.isValidImport ?? discovery?.isValidImport) == true;
  }

  Iterable<DriftImport>? get imports =>
      discovery?.importDependencies ?? cachedDiscovery?.imports;

  String get extension => url.extension(ownUri.path);

  /// Whether this file contains a drift database or a drift accessor / DAO.
  bool get containsDatabaseAccessor {
    return analyzedElements.any((e) => e is BaseDriftAccessor);
  }

  Iterable<ExistingDriftElement> get definedElements {
    final discovery = this.discovery;
    final cached = cachedDiscovery;

    if (discovery != null) {
      return discovery.locallyDefinedElements;
    } else if (cached != null) {
      return cached.locallyDefinedElements;
    } else {
      return const Iterable.empty();
    }
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

  bool get _definesQuery {
    return analyzedElements
            .any((e) => e is DefinedSqlQuery && e.mode == QueryMode.regular) ||
        // Also check discovery, we might not have analyzed all elements in this
        // file if it's just an import.
        discovery?.locallyDefinedElements.any((e) =>
                e is DiscoveredDriftStatement && e.sqlNode.isRegularQuery) ==
            true;
  }

  /// Whether an accessor class making queries and imports available should be
  /// written for this file if modular analysis is enabled.
  ///
  /// This is the case if this accessor defines queries or if it transitively
  /// imports a modular accessor.
  bool needsModularAccessor(DriftAnalysisDriver driver) {
    if (_needsModularAccessor != null) return _needsModularAccessor!;

    return _needsModularAccessor = driver.cache.crawl(this).any((e) {
      return e._definesQuery;
    });
  }
}

class CachedDiscoveryResults {
  final bool isValidImport;
  final List<DriftImport> imports;
  final List<ExistingDriftElement> locallyDefinedElements;

  CachedDiscoveryResults(
    this.isValidImport,
    this.imports,
    this.locallyDefinedElements,
  );
}

abstract class DiscoveredFileState {
  final List<DiscoveredElement> locallyDefinedElements;

  bool get isValidImport => false;

  Iterable<DriftImport> get importDependencies => const [];

  DiscoveredFileState(this.locallyDefinedElements);
}

class DiscoveredDriftFile extends DiscoveredFileState {
  final String originalSource;
  final DriftFile ast;
  final List<DriftFileImport> imports;

  @override
  bool get isValidImport => true;

  @override
  Iterable<DriftImport> get importDependencies => imports.map((e) => (
        uri: e.importedUri,
        // Imports in drift files are always transitive (visible to files
        // importing this drift file).
        transitive: true,
      ));

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
  final List<DriftImport> importDependencies;

  @override
  bool get isValidImport => true;

  DiscoveredDartLibrary(
    this.library,
    super.locallyDefinedElements,
    this.importDependencies,
  );
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

class ExistingDriftElement {
  final DriftElementId ownId;
  final DriftElementKind kind;

  /// When this element was defined via a Dart class, the name of that class.
  ///
  /// Together with the [DriftElementId.libraryUri] of the [id], this can be
  /// used to find the Drift element for an [Element] without resolving all
  /// available imports multiple times.
  final String? dartElementName;

  ExistingDriftElement({
    required this.ownId,
    required this.kind,
    this.dartElementName,
  });
}

/// Information about the syntax of a known drift element which can be used to
/// fully resolve it.
abstract class DiscoveredElement implements ExistingDriftElement {
  @override
  final DriftElementId ownId;
  @override
  DriftElementKind get kind;

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
