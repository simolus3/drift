import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:sqlparser/sqlparser.dart';

import '../options.dart';
import '../backend.dart';
import '../drift_native_functions.dart';
import '../resolver/dart/helper.dart';
import '../resolver/discover.dart';
import '../resolver/drift/sqlparser/mapping.dart';
import '../resolver/file_analysis.dart';
import '../resolver/queries/custom_known_functions.dart';
import '../resolver/resolver.dart';
import '../results/results.dart';
import '../serializer.dart';
import 'cache.dart';
import 'error.dart';
import 'state.dart';

/// The main entrypoint for drift element analysis.
///
/// The purpose of this analyzer is to extract tables, views, databases and
/// other elements of interest to drift from source files. Where possible, the
/// analysis steps should be modular, meaning that they don't require a central
/// entrypoint like a database class. Instead, every element can be analyzed in
/// isolation (except for its dependencies).
///
/// Analysis currently happens in three stages:
///
///  1. __Discovery__: In this first step, the names and types of drift elements
///  is detected in each file. After this step, we might know that there's a
///  table named "users" in a file named "tables.drift", but we don't know its
///  columns yet. This enables the analysis stage to efficiently resolve
///  references. The step is mainly implemented in [DiscoverStep] and
///  [prepareFileForAnalysis].
///  2. __Element analysis__: In this step, discovered entries from the first
///  step are fully resolved.
///  Resolving elements happens in a depth-first approach, where dependencies
///  are analyzed before dependants. It is forbidden to have circular references
///  between elements (which is detected and handled gracefully). This step is
///  coordinated by a [DriftResolver], with the classes in `resolver/dart` and
///  `resolver/drift` being responsible for the individual analysis work for
///  different element types.
///  3. __File analysis__: In this final step, some elements are analyzed again
///  to fully resolve them. This includes drift databases, drift accessors and
///  queries defined in `.drift` files. They require all other elements to be
///  fully analyzed.
///  The main motivation for this being a third step is that the results of
///  resolving queries are very difficult to serialize. At the moment, modular
///  analysis is implemented by serializing the results of the second step
///  (element analysis). By running file analysis later and only for entrypoints
///  where that is required, we obtain a reasonable degree of modularity without
///  having to serialize the complex model of serialized queries.
class DriftAnalysisDriver {
  final DriftBackend backend;
  final DriftAnalysisCache cache = DriftAnalysisCache();
  final DriftOptions options;
  final bool _isTesting;

  late final TypeMapping typeMapping = TypeMapping(this);

  AnalysisResultCacheReader? cacheReader;

  KnownDriftTypes? _knownTypes;

  DriftAnalysisDriver(this.backend, this.options, {bool isTesting = false})
      : _isTesting = isTesting;

  SqlEngine newSqlEngine() {
    return SqlEngine(
      EngineOptions(
        driftOptions: DriftSqlOptions(
          storeDateTimesAsText: options.storeDateTimeValuesAsText,
        ),
        enabledExtensions: [
          DriftOptionsExtension(options),
          if (options.hasModule(SqlModule.fts5)) const Fts5Extension(),
          if (options.hasModule(SqlModule.json1)) const Json1Extension(),
          if (options.hasModule(SqlModule.moor_ffi))
            const DriftNativeExtension(),
          if (options.hasModule(SqlModule.math)) const BuiltInMathExtension(),
          if (options.hasModule(SqlModule.rtree)) const RTreeExtension(),
          if (options.hasModule(SqlModule.spellfix1))
            const Spellfix1Extension(),
        ],
        version: options.sqliteVersion,
      ),
    );
  }

  /// Loads types important for Drift analysis.
  Future<KnownDriftTypes> loadKnownTypes() async {
    return _knownTypes ??= await KnownDriftTypes.resolve(this);
  }

  /// For a given file under [uri], attempts to restore serialized analysis
  /// results that have been stored before.
  ///
  /// Returns non-null if analysis results were found and successfully restored.
  Future<Map<String, Object?>?> readStoredAnalysisResult(Uri uri) async {
    if (cache.serializationCache.containsKey(uri)) {
      return cache.serializationCache[uri]?.cachedElements;
    }

    // Not available in in-memory cache, so let's read it from the file system.
    final reader = cacheReader;
    if (reader == null) return null;

    final found = await reader.readElementCacheFor(uri);
    if (found == null) return null;

    final parsed = json.decode(found) as Map<String, Object?>;
    final data = CachedSerializationResult(
      [
        for (final entry in parsed['imports'] as List)
          Uri.parse(entry as String)
      ],
      (parsed['elements'] as Map<String, Object?>).cast(),
    );
    cache.serializationCache[uri] = data;
    return data.cachedElements;
  }

  Future<void> discoverIfNecessary(
    FileState file, {
    bool warnIfFileDoesntExist = true,
  }) async {
    if (file.discovery == null) {
      await DiscoverStep(this, file)
          .discover(warnIfFileDoesntExist: warnIfFileDoesntExist);
      cache.knowsLocalElements(file);
    }
  }

  /// Runs the first step (discovering local elements) on a file with the given
  /// [uri].
  Future<FileState> findLocalElements(
    Uri uri, {
    bool warnIfFileDoesntExist = true,
  }) async {
    final known = cache.knownFiles[uri] ?? cache.notifyFileChanged(uri);

    if (known.cachedDiscovery != null || known.discovery != null) {
      // We already know local elements.
      return known;
    }

    // First, try to read cached results.
    final reader = cacheReader;
    CachedDiscoveryResults? cached;

    if (reader != null) {
      cached = await reader.readDiscovery(uri);

      if (cached == null && reader.findsLocalElementsReliably) {
        // There are no locally defined elements, since otherwise the reader
        // would have found them.
        cached = CachedDiscoveryResults(false, const [], const []);
      }
    }

    if (cached != null) {
      known.cachedDiscovery = cached;
      cache.knowsLocalElements(known);
    } else {
      await discoverIfNecessary(
        known,
        warnIfFileDoesntExist: warnIfFileDoesntExist,
      );
    }

    return known;
  }

  Future<void> _warnAboutUnresolvedImportsInDriftFile(FileState known) async {
    final state = known.discovery;
    if (state is DiscoveredDriftFile) {
      for (final import in state.imports) {
        final file = await findLocalElements(import.importedUri);

        if (file.isValidImport != true) {
          known.errorsDuringDiscovery.add(
            DriftAnalysisError.inDriftFile(
              import.ast,
              'The imported file, `${import.importedUri}`, does not exist or '
              "can't be imported.",
            ),
          );
        }
      }
    }
  }

  /// Analyzes elements known to be defined in [state], or restores them from
  /// cache.
  ///
  /// Elements in the file must be known at this point - either because the file
  /// was discovered or because discovered elements have been imported from
  /// cache.
  Future<void> _analyzeLocalElements(FileState state) async {
    for (final discovered in state.definedElements) {
      await resolveElement(state, discovered.ownId);
    }
  }

  Future<DriftElement?> resolveElement(
      FileState state, DriftElementId id) async {
    assert(state.discovery != null || state.cachedDiscovery != null);
    assert(id.libraryUri == state.ownUri);

    if (!state.elementIsAnalyzed(id)) {
      final resolver = DriftResolver(this);

      try {
        return await resolver.resolveEntrypoint(id);
      } catch (e, s) {
        if (e is! CouldNotResolveElementException) {
          backend.log.warning('Could not analyze $id', e, s);

          if (_isTesting) rethrow;
        }
      }
    }

    return null;
  }

  /// Resolves elements in a file under the given [uri] by doing all the
  /// necessary work up until that point.
  Future<FileState> resolveElements(Uri uri) async {
    var known = cache.stateForUri(uri);
    if (known.isFullyAnalyzed) {
      // Well, there's nothing to do now.
      return known;
    }

    // We couldn't recover all analyzed elements. Let's run an analysis run
    // then.
    await findLocalElements(uri);
    await _warnAboutUnresolvedImportsInDriftFile(known);

    // Also make sure elements in transitive imports have been resolved.
    final seen = cache.knownFiles.keys.toSet();
    final pending = <Uri>[known.ownUri];

    while (pending.isNotEmpty) {
      final file = pending.removeLast();
      seen.add(file);

      final fileState = await findLocalElements(
        file,
        // We might import a generated file that doesn't exist yet, that
        // should not be a user-visible error. Users will notice because the
        // import is reported as an error by the analyzer either way.
        warnIfFileDoesntExist: true,
      );

      for (final dependency in fileState.imports ?? const <DriftImport>[]) {
        final considerImport = file == known.ownUri || dependency.transitive;

        if (considerImport && !seen.contains(dependency.uri)) {
          pending.add(dependency.uri);
        }
      }
    }

    await _analyzeLocalElements(known);
    return known;
  }

  /// Fully analyzes a file under the [uri] by running all analysis steps.
  Future<FileState> fullyAnalyze(Uri uri) async {
    // First, make sure that elements in this file and all imports are fully
    // resolved.
    final state = await resolveElements(uri);

    // Then, run local analysis if needed
    if (state.fileAnalysis == null) {
      final analyzer = FileAnalyzer(this);
      final result = await analyzer.runAnalysisOn(state);

      state.fileAnalysis = result;
    }

    return state;
  }

  /// Serializes imports and locally-defined elements of the file.
  ///
  /// Serialized data can later be recovered if a [cacheReader] is set on this
  /// driver, which avoids running duplicate analysis runs across build steps.
  SerializedElements serializeState(FileState state) {
    final data = ElementSerializer.serialize(
        state.analysis.values.map((e) => e.result).whereType());

    final imports = state.discovery?.importDependencies;
    if (imports != null) {
      data.serializedData['imports'] = [
        for (final import in imports) import.uri.toString()
      ];
    }

    return data;
  }
}

/// Reads serialized data and a generated Dart helper file used to serialize
/// drift elements.
///
/// Drift's element serializer generates two output: A JSON structure of all
/// elements, and a helper `.dart` file containing `typedef`s for every Dart
/// type referenced in the elements.
///
/// This class is responsible for recovering both assets in a subsequent build-
/// step.
abstract class AnalysisResultCacheReader {
  /// Whether [readDiscovery] only returns `null` when the file under the URI
  /// is not relevant to drift.
  bool get findsLocalElementsReliably;

  /// Whether [readElementCacheFor] is guaranteed to return all elements defined
  /// in the supplied `uri`, or whether it could be that we just didn't analyze
  /// that file yet.
  bool get findsResolvedElementsReliably;

  Future<CachedDiscoveryResults?> readDiscovery(Uri uri);

  Future<LibraryElement?> readTypeHelperFor(Uri uri);
  Future<String?> readElementCacheFor(Uri uri);
}

/// Thrown by a local element resolver when an element could not be resolved and
/// a more helpful error has already been added as an analysis error for the
/// user to see.
class CouldNotResolveElementException implements Exception {
  const CouldNotResolveElementException();
}
