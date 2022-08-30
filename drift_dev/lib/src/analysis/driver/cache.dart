import '../results/element.dart';
import 'state.dart';

class DriftAnalysisCache {
  final Map<Uri, FileState> knownFiles = {};
  final Map<DriftElementId, DiscoveredElement> discoveredElements = {};
  final Map<DriftElementId, DriftElement> resolvedElements = {};

  FileState notifyFileChanged(Uri uri) {
    // todo: Mark references for files that import this one as stale.
    // todo: Mark elements that reference an element in this file as stale.

    return knownFiles.putIfAbsent(uri, () => FileState(uri))
      ..errorsDuringDiscovery.clear()
      ..errorsDuringAnalysis.clear()
      ..results = null
      ..discovery = null;
  }

  void notifyFileDeleted(Uri uri) {}

  /// From a given [entrypoint], yield the [entrypoint] itself and all
  /// transitive imports.
  ///
  /// This assumes that pre-analysis has already happened for all transitive
  /// imports, meaning that [knownFiles] contains an entry for every import URI.
  Iterable<FileState> crawl(FileState entrypoint) sync* {
    final seenUris = <Uri>{entrypoint.ownUri};
    final pending = [entrypoint];

    while (pending.isNotEmpty) {
      final found = pending.removeLast();
      yield found;

      for (final imported
          in found.discovery?.importDependencies ?? const <Uri>[]) {
        if (!seenUris.add(imported)) {
          pending.add(knownFiles[imported]!);
        }
      }
    }
  }
}
