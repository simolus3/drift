import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
// ignore: implementation_imports
import 'package:drift/src/utils/synchronized.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/session.dart';
import 'package:drift_dev/src/utils/options_reader.dart' as options;
import 'package:logging/logging.dart';

import '../standalone.dart';

class MoorDriver {
  final ResourceProvider _resourceProvider;
  final Lock lock = Lock();

  late final MoorSession session;
  late StandaloneBackend backend;
  late AnalysisContext context;

  StreamSubscription? _fileChangeSubscription;
  StreamSubscription? _taskCompleteSubscription;

  MoorDriver(this._resourceProvider,
      {required String contextRoot,
      String? sdkPath,
      DriftOptions options = const DriftOptions.defaults()}) {
    final overlayed = OverlayResourceProvider(_resourceProvider);
    final collection = AnalysisContextCollection(
        includedPaths: [contextRoot],
        resourceProvider: overlayed,
        sdkPath: sdkPath);
    context = collection.contextFor(contextRoot);
    backend = StandaloneBackend(context, overlayed);

    // Options will be loaded later.
    session = MoorSession(backend, options: options);
  }

  MoorDriver.forContext(this._resourceProvider, this.context) {
    final overlayed = OverlayResourceProvider(_resourceProvider);
    backend = StandaloneBackend(context, overlayed);
    session = MoorSession(backend, options: const DriftOptions.defaults());
  }

  bool _ownsFile(String path) =>
      path.endsWith('.moor') ||
      path.endsWith('.drift') ||
      path.endsWith('.dart');

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

      // Also trigger analysis for this path
      waitFileParsed(path);
    }
  }

  /// Attempt to load the appropriate [DriftOptions] by reading the `build.yaml`
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
  Future<FoundFile?> waitFileParsed(String path) async {
    if (!_ownsFile(path)) {
      return null;
    }

    final found = pathToFoundFile(path);

    if (found.isParsed) {
      return found;
    } else {
      final result = Completer<FoundFile?>();

      unawaited(session
          .completedFiles()
          .firstWhere((file) => file == found && file.isParsed)
          .then((file) {
        if (!result.isCompleted) {
          result.complete(file);
        }
      }));

      try {
        await _runTask(path);
      } on Exception {
        result.complete(null);
      }

      return result.future;
    }
  }

  Future<Object> _runTask(String path) {
    return lock.synchronized(() {
      final backendTask = backend.newTask(Uri.file(path));
      final task = session.startTask(backendTask);
      return task.runTask();
    });
  }
}
