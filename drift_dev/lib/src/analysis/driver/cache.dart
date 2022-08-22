import '../results/element.dart';
import 'state.dart';

class DriftAnalysisCache {
  final Map<Uri, FileState> knownFiles = {};
  final Map<DriftElementId, DiscoveredElement> knownElements = {};

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
}
