import 'dart:convert';

import 'package:sqlparser/sqlparser.dart';

import '../../analyzer/options.dart';
import '../backend.dart';
import '../drift_native_functions.dart';
import '../resolver/dart/helper.dart';
import '../resolver/discover.dart';
import '../resolver/drift/sqlparser/mapping.dart';
import '../resolver/file_analysis.dart';
import '../resolver/resolver.dart';
import '../results/results.dart';
import '../serializer.dart';
import 'cache.dart';
import 'error.dart';
import 'state.dart';

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
        useDriftExtensions: true,
        enabledExtensions: [
          if (options.hasModule(SqlModule.fts5)) const Fts5Extension(),
          if (options.hasModule(SqlModule.json1)) const Json1Extension(),
          if (options.hasModule(SqlModule.moor_ffi))
            const DriftNativeExtension(),
          if (options.hasModule(SqlModule.math)) const BuiltInMathExtension(),
          if (options.hasModule(SqlModule.rtree)) const RTreeExtension(),
        ],
        version: options.sqliteVersion,
      ),
    );
  }

  Future<KnownDriftTypes> loadKnownTypes() async {
    return _knownTypes ??= await KnownDriftTypes.resolve(this);
  }

  Future<Map<String, Object?>?> readStoredAnalysisResult(Uri uri) async {
    final cached = cache.serializedElements[uri];
    if (cached != null) return cached;

    // Not available in in-memory cache, so let's read it from the file system.
    final reader = cacheReader;
    if (reader == null) return null;

    final found = await reader.readCacheFor(uri);
    if (found == null) return null;

    final parsed = json.decode(found) as Map<String, Object?>;
    return cache.serializedElements[uri] = parsed;
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

    return allRecovered;
  }

  Future<FileState> prepareFileForAnalysis(Uri uri,
      {bool needsDiscovery = true}) async {
    var known = cache.knownFiles[uri] ?? cache.notifyFileChanged(uri);

    if (known.discovery == null && needsDiscovery) {
      await DiscoverStep(this, known).discover();
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
      }
    }

    return known;
  }

  Future<void> _analyzePrepared(FileState state) async {
    assert(state.discovery != null);

    for (final discovered in state.discovery!.locallyDefinedElements) {
      if (!state.elementIsAnalyzed(discovered.ownId)) {
        final resolver = DriftResolver(this);

        try {
          await resolver.resolveDiscovered(discovered);
        } catch (e, s) {
          backend.log.warning('Could not analyze ${discovered.ownId}', e, s);
        }
      }
    }
  }

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
}

abstract class AnalysisResultCacheReader {
  Future<String?> readCacheFor(Uri uri);
}
