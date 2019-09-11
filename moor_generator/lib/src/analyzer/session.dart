import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';
import 'package:moor_generator/src/backends/backend.dart';
import 'package:path/path.dart' as p;

const _fileEndings = {
  '.moor': FileType.moor,
  '.dart': FileType.dart,
};

/// Will store cached data about files that have already been analyzed.
class MoorSession {
  final FileGraph fileGraph = FileGraph();
  final Backend backend;

  MoorSession(this.backend);

  FileType _findFileType(String path) {
    final extension = p.extension(path);

    return _fileEndings[extension] ?? FileType.other;
  }

  /// Resolves an import directive in the context of the [source] file. This
  /// can handle both relative imports and `package:` imports.
  FoundFile resolve(FoundFile source, String import) {
    final resolvedUri = backend.resolve(source.uri, import);
    return _uriToFile(resolvedUri);
  }

  /// Registers a file by its absolute uri.
  FoundFile registerFile(Uri file) => _uriToFile(file);

  FoundFile _uriToFile(Uri uri) {
    return fileGraph.registerFile(uri, () {
      return FoundFile(uri, _findFileType(uri.path));
    });
  }

  Task startTask(BackendTask backend) {
    return Task(this, _uriToFile(backend.entrypoint), backend);
  }
}
