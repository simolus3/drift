import 'package:sqlparser/sqlparser.dart';

import '../analyzer/options.dart';
import 'backend.dart';
import 'cache.dart';

class DriftAnalysisDriver {
  final DriftBackend backend;
  final DriftAnalysisCache cache = DriftAnalysisCache();
  final DriftOptions options;

  DriftAnalysisDriver(this.backend, this.options);

  SqlEngine _newSqlEngine() {
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

  /// Identify all [PendingDriftElement]s in a file.
  Future<void> _discover(FileState state) async {
    final extension = state.extension;

    switch (extension) {
      case '.dart':
        try {
          state
            ..parsedDartFile = await backend.readDart(state.uri)
            ..kind = FileKind.dartLibrary;
        } catch (e, s) {
          backend.log
              .fine('Could not read Dart library from ${state.uri}', e, s);
          state.kind = FileKind.invalid;
        }
        break;
      case '.drift':
      case '.moor':
        final engine = _newSqlEngine();
        String contents;
        try {
          contents = await backend.readAsString(state.uri);
          state.kind = FileKind.driftFile;
        } catch (e, s) {
          backend.log.fine('Could not read drift sources ${state.uri}', e, s);
          state.kind = FileKind.invalid;
          break;
        }

        // todo: Handle parse errors
        final parsed = engine.parseDriftFile(contents);
        state.parsedDriftFile = parsed.rootNode as DriftFile;

        break;
    }
  }

  Future<void> fullyAnalyze(Uri uri) async {
    var known = cache.knownFiles[uri];

    if (known == null || !known.contentsFresh) {
      await _discover(cache.notifyFileChanged(uri));
    }
  }
}
