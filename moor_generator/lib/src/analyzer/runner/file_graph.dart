//@dart=2.9
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';

import '../errors.dart';

/// Represents found files as nodes and import statements as edges.
class FileGraph {
  final Map<Uri, FoundFile> _files;
  final UnmodifiableListView<FoundFile> files;

  final Map<FoundFile, List<FoundFile>> _imports = {};
  final Map<FoundFile, List<FoundFile>> _transposedImports = {};

  // using a factory constructor here to the readonly fields can be final
  factory FileGraph() {
    final files = <Uri, FoundFile>{};
    final filesView = UnmodifiableListView(files.values);

    return FileGraph._(files, filesView);
  }

  FileGraph._(this._files, this.files);

  /// Checks if a file with the given [uri] is registered in this graph. If it's
  /// not, it will be created via [create] and inserted.
  FoundFile registerFile(Uri uri, FoundFile Function() create) {
    return _files.putIfAbsent(uri, create);
  }

  /// Finds all files that [file] transitively imports (or, if [transposed] is
  /// true, is transitively imported by).
  Iterable<FoundFile> crawl(FoundFile file, {bool transposed = false}) {
    final edges = transposed ? _transposedImports : _imports;

    // breadth first search
    final found = <FoundFile>{};
    final unhandled = Queue<FoundFile>()..add(file);

    while (unhandled.isNotEmpty) {
      final file = unhandled.removeFirst();
      final neighbors = edges[file];

      if (neighbors != null) {
        for (final neighbor in neighbors) {
          // if the neighbor wasn't in the set, also add to unhandled nodes so
          // that we crawl its imports later.
          if (found.add(neighbor)) {
            unhandled.add(neighbor);
          }
        }
      }
    }

    return found;
  }

  void setImports(FoundFile file, List<FoundFile> updatedImports) {
    registerFile(file.uri, () => file);

    // clear old imports, we also need to take the transposed imports into
    // account here
    if (_imports.containsKey(file)) {
      for (final oldImport in _imports[file]) {
        _transposedImports[oldImport]?.remove(file);
      }
      _imports.remove(file);
    }

    _imports[file] = updatedImports;

    for (final newImport in updatedImports) {
      _transposedImports.putIfAbsent(newImport, () => []).add(file);
    }
  }
}

enum FileType {
  /// A `.moor` file, containing `CREATE TABLE` statements and queries.
  moor,

  /// A dart library. Note that, in particular, this doesn't include `part of`
  /// files, as those aren't libraries.
  dartLibrary,

  /// Other files
  other,
}

enum FileState {
  /// The file was discovered, but not handled yet
  dirty,

  /// The file completed the first step in the analysis task, which means that
  /// the overall structure was parsed.
  parsed,

  /// The file is fully analyzed, which means that all information is fully
  /// available
  analyzed
}

class FoundFile {
  /// The uri of this file, which can be an asset on the build backend or a
  /// `file://` uri on the analysis plugin backend.
  final Uri uri;
  FileType type;

  FileResult currentResult;
  FileState state = FileState.dirty;
  final ErrorSink errors = ErrorSink();

  FoundFile(this.uri, this.type) : assert(uri.isAbsolute);

  String get shortName => uri.pathSegments.last;

  bool get isParsed => state != FileState.dirty;
  bool get isAnalyzed => state == FileState.analyzed;

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is FoundFile && other.uri == uri;
  }

  @override
  String toString() {
    return 'FoundFile($uri, $type)';
  }
}
