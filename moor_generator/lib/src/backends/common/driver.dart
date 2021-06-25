//@dart=2.9
import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:logging/logging.dart';
import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/services/ide/moor_ide.dart';
import 'package:moor_generator/src/utils/options_reader.dart' as options;

import '../standalone.dart';

class MoorDriver {
  MoorIde ide;

  final ResourceProvider _resourceProvider;

  /* late final */ MoorSession session;
  StandaloneBackend backend;
  AnalysisContext context;

  StreamSubscription _fileChangeSubscription;
  StreamSubscription _taskCompleteSubscription;

  MoorDriver(this._resourceProvider,
      [MoorOptions options, String contextRoot]) {
    final collection = AnalysisContextCollection(
        includedPaths: [contextRoot], resourceProvider: _resourceProvider);
    context = collection.contextFor(contextRoot);
    backend = StandaloneBackend(context);

    session =
        MoorSession(backend, options: options ?? const MoorOptions.defaults());
    ide = MoorIde(session, _DriverBasedFileManagement(this));
  }

  bool _ownsFile(String path) =>
      path.endsWith('.moor') || path.endsWith('.dart');

  FoundFile pathToFoundFile(String path) {
    final uri = _resourceProvider.pathContext.toUri(path);
    return session.registerFile(uri);
  }

  void addFile(String path) {
    if (_ownsFile(path)) {
      final file = pathToFoundFile(path);
      _potentiallyNewFile(file);
    }
  }

  void dispose() {
    _fileChangeSubscription?.cancel();
    _taskCompleteSubscription?.cancel();
  }

  void _potentiallyNewFile(FoundFile file) {
    final path = _resourceProvider.pathContext.fromUri(file.uri);
    if (!file.isParsed) {
      handleFileChanged(path);
    }
  }

  void handleFileChanged(String path) {
    if (_ownsFile(path)) {
      session.notifyFileChanged(pathToFoundFile(path));
    }
  }

  /// Attempt to load the appropriate [MoorOptions] by reading the `build.yaml`
  /// located in the context root.
  ///
  /// When something fails, the default options will be used an an error message
  /// will be logged.
  Future<void> tryToLoadOptions() async {
    try {
      final result = await options.fromRootDir(context.contextRoot.root.path);
      session.options = result;
    } catch (e, s) {
      Logger.root.info('Could not load options, using defaults', e, s);
    }
  }

  String readFile(String path) {
    final file = _resourceProvider.getFile(path);
    return file.exists ? file.readAsStringSync() : '';
  }

  /// Waits for the file at [path] to be parsed. If the file is neither a Dart
  /// or a moor file, returns `null`.
  Future<FoundFile> waitFileParsed(String path) {
    if (!_ownsFile(path)) {
      return Future.value(null);
    }

    final found = pathToFoundFile(path);
    _potentiallyNewFile(found);

    if (found.isParsed) {
      return Future.value(found);
    } else {
      final backendTask = backend.newTask(Uri.file(path));
      final task = session.startTask(backendTask);
      task.runTask();

      return session
          .completedFiles()
          .firstWhere((file) => file == found && file.isParsed);
    }
  }
}

class _DriverBasedFileManagement implements IdeFileManagement {
  final MoorDriver driver;

  _DriverBasedFileManagement(this.driver);

  @override
  Uri fsPathToUri(String path) {
    return driver._resourceProvider.pathContext.toUri(path);
  }

  @override
  Future<void> waitUntilParsed(String path) {
    return driver.waitFileParsed(path);
  }
}
