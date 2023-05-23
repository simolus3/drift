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

  late final TypeMapping typeMapping = TypeMapping(this);
  late final ElementDeserializer deserializer = ElementDeserializer(this);

  AnalysisResultCacheReader? cacheReader;

  KnownDriftTypes? _knownTypes;

  DriftAnalysisDriver(this.backend, this.options);

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
    final cached = cache.serializationCache[uri];
    if (cached != null) return cached.cachedElements;

    // Not available in in-memory cache, so let's read it from the file system.
    final reader = cacheReader;
    if (reader == null) return null;

    final found = await reader.readCacheFor(uri);
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

  Future<bool> _recoverFromCache(FileState state) async {
    final stored = await readStoredAnalysisResult(state.ownUri);
    if (stored == null) return false;

    var allRecovered = true;

    for (final local in stored.keys) {
      final id = DriftElementId(state.ownUri, local);
      try {
        await deserializer.readDriftElement(id);
      } on CouldNotDeserializeException catch (e, s) {
        backend.log.fine('Could not deserialize $id', e, s);
        allRecovered = false;
      }
    }

    final cachedImports = cache.serializationCache[state.ownUri]?.cachedImports;
    if (cachedImports != null && state.discovery == null) {
      state.cachedImports = cachedImports;
      for (final import in cachedImports) {
        final found = cache.stateForUri(import);

        if (found.imports == null) {
          // Attempt to recover this file as well to make sure we know the
          // imports for every file transitively reachable from the sources
          // analyzed.
          await _recoverFromCache(found);
        }
      }
    }

    return allRecovered;
  }

  /// Runs the first step (element discovery) on a file with the given [uri].
  Future<FileState> prepareFileForAnalysis(
    Uri uri, {
    bool needsDiscovery = true,
    bool warnIfFileDoesntExist = true,
  }) async {
    var known = cache.knownFiles[uri] ?? cache.notifyFileChanged(uri);

    if (known.discovery == null && needsDiscovery) {
      await DiscoverStep(this, known)
          .discover(warnIfFileDoesntExist: warnIfFileDoesntExist);
      cache.postFileDiscoveryResults(known);

      // todo: Mark elements that need to be analyzed again

      // To analyze a drift file, we also need to be able to analyze imports.
      final state = known.discovery;
      if (state is DiscoveredDriftFile) {
        for (final import in state.imports) {
          // todo: We shouldn't unconditionally crawl files like this. The build
          // backend should emit prepared file results in a previous step which
          // should be used here.
          final file = await prepareFileForAnalysis(import.importedUri);

          if (file.discovery?.isValidImport != true) {
            known.errorsDuringDiscovery.add(
              DriftAnalysisError.inDriftFile(
                import.ast,
                'The imported file, `${import.importedUri}`, does not exist or '
                "can't be imported.",
              ),
            );
          }
        }
      } else if (state is DiscoveredDartLibrary) {
        for (final import in state.importDependencies) {
          // We might import a generated file that doesn't exist yet, that
          // should not be a user-visible error. Users will notice because the
          // import is reported as an error by the analyzer either way.
          await prepareFileForAnalysis(import, warnIfFileDoesntExist: false);
        }
      }
    }

    return known;
  }

  /// Runs the second analysis step (element analysis) on a file.
  ///
  /// The file, as well as all imports, should have undergone the first analysis
  /// step (discovery) at this point, so that the resolver is able to
  /// recognize dependencies between different elements.
  Future<void> _analyzePrepared(FileState state) async {
    assert(state.discovery != null);

    for (final discovered in state.discovery!.locallyDefinedElements) {
      if (!state.elementIsAnalyzed(discovered.ownId)) {
        final resolver = DriftResolver(this);

        try {
          await resolver.resolveDiscovered(discovered);
        } catch (e, s) {
          if (e is! CouldNotResolveElementException) {
            backend.log.warning('Could not analyze ${discovered.ownId}', e, s);
          }
        }
      }
    }
  }

  /// Resolves elements in a file under the given [uri] by doing all the
  /// necessary work up until that point.
  Future<FileState> resolveElements(Uri uri) async {
    var known = cache.stateForUri(uri);
    await prepareFileForAnalysis(uri, needsDiscovery: false);

    if (known.isFullyAnalyzed) {
      // Well, there's nothing to do now.
      return known;
    }

    final allRecoveredFromCache = await _recoverFromCache(known);
    if (allRecoveredFromCache) {
      // We were able to read all elements from cache, so we don't have to
      // run any analysis now.
      return known;
    }

    // We couldn't recover all analyzed elements. Let's run an analysis run
    // now then.
    await prepareFileForAnalysis(uri, needsDiscovery: true);
    await _analyzePrepared(known);
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
        for (final import in imports) import.toString()
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
  Future<LibraryElement?> readTypeHelperFor(Uri uri);
  Future<String?> readCacheFor(Uri uri);
}

/// Thrown by a local element resolver when an element could not be resolved and
/// a more helpful error has already been added as an analysis error for the
/// user to see.
class CouldNotResolveElementException implements Exception {
  const CouldNotResolveElementException();
}
