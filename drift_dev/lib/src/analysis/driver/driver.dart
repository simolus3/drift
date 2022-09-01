import 'package:meta/meta.dart';
import 'package:sqlparser/sqlparser.dart';

import '../../analyzer/options.dart';
import '../backend.dart';
import '../resolver/discover.dart';
import '../resolver/resolver.dart';
import 'cache.dart';
import 'error.dart';
import 'state.dart';

class DriftAnalysisDriver {
  final DriftBackend backend;
  final DriftAnalysisCache cache = DriftAnalysisCache();
  final DriftOptions options;

  DriftAnalysisDriver(this.backend, this.options);

  SqlEngine newSqlEngine() {
    return SqlEngine(
      EngineOptions(
        useDriftExtensions: true,
        enabledExtensions: [
          // todo: Map from options
        ],
        version: options.sqliteVersion,
      ),
    );
  }

  @visibleForTesting
  Future<FileState> prepareFileForAnalysis(Uri uri) async {
    var known = cache.knownFiles[uri] ?? cache.notifyFileChanged(uri);

    if (known.discovery == null) {
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
        await resolver.resolveDiscovered(discovered);
      }
    }
  }

  Future<FileState> fullyAnalyze(Uri uri) async {
    var known = cache.knownFiles[uri];

    if (known == null || known.discovery == null) {
      known = await prepareFileForAnalysis(uri);
    }

    await _analyzePrepared(known);
    return known;
  }
}
