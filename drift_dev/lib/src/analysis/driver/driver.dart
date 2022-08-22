import 'package:sqlparser/sqlparser.dart';

import '../../analyzer/options.dart';
import '../backend.dart';
import '../resolver/discover.dart';
import 'cache.dart';

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

  Future<void> fullyAnalyze(Uri uri) async {
    var known = cache.knownFiles[uri];

    if (known == null || known.discovery == null) {
      await DiscoverStep(this, cache.notifyFileChanged(uri)).discover();
    }
  }
}
