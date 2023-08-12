import '../results/element.dart';
import 'state.dart';

/// An in-memory cache of analysis results for drift elements.
///
/// At the moment, the cache is not set up to handle changing files.
class DriftAnalysisCache {
  final Map<Uri, CachedSerializationResult> serializationCache = {};
  final Map<Uri, FileState> knownFiles = {};
  final Map<DriftElementId, DriftElementKind> discoveredElements = {};

  FileState stateForUri(Uri uri) {
    return knownFiles[uri] ?? notifyFileChanged(uri);
  }

  FileState notifyFileChanged(Uri uri) {
    // todo: Mark references for files that import this one as stale.
    // todo: Mark elements that reference an element in this file as stale.
    serializationCache.remove(uri);

    return knownFiles.putIfAbsent(uri, () => FileState(uri))
      ..errorsDuringDiscovery.clear()
      ..analysis.clear()
      ..discovery = null;
  }

  void notifyFileDeleted(Uri uri) {}

  void knowsLocalElements(FileState state) {
    discoveredElements.removeWhere((key, _) => key.libraryUri == state.ownUri);

    for (final (id, kind) in state.definedElements) {
      discoveredElements[id] = kind;
    }
  }

  /// From a given [entrypoint], yield the [entrypoint] itself and all
  /// transitive imports.
  ///
  /// This assumes that pre-analysis has already happened for all transitive
  /// imports, meaning that [knownFiles] contains an entry for every import URI.
  Iterable<FileState> crawl(FileState entrypoint) {
    return crawlMulti([entrypoint]);
  }

  /// Crawls all dependencies from a set of [entrypoints].
  Iterable<FileState> crawlMulti(Iterable<FileState> entrypoints) sync* {
    final seenUris = <Uri>{};
    final pending = <FileState>[];

    for (final initial in entrypoints) {
      if (seenUris.add(initial.ownUri)) {
        pending.add(initial);
      }
    }

    while (pending.isNotEmpty) {
      final found = pending.removeLast();
      yield found;

      for (final imported in found.imports ?? const <Uri>[]) {
        // We might not have a known file for all imports of a Dart file, since
        // not all imports are drift-related there.
        final knownImport = knownFiles[imported];

        if (seenUris.add(imported) && knownImport != null) {
          pending.add(knownImport);
        }
      }
    }
  }
}

class CachedSerializationResult {
  final List<Uri> cachedImports;
  final Map<String, Map<String, Object?>> cachedElements;

  CachedSerializationResult(this.cachedImports, this.cachedElements);
}
