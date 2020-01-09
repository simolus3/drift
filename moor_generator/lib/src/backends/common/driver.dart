// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/source.dart' show SourceKind;
import 'package:logging/logging.dart';
import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/services/ide/moor_ide.dart';

import 'backend.dart';
import 'file_tracker.dart';

class MoorDriver implements AnalysisDriverGeneric {
  final FileTracker _tracker;

  final AnalysisDriverScheduler _scheduler;
  final AnalysisDriver dartDriver;
  MoorIde ide;

  /// The content overlay exists so that we can perform up-to-date analysis on
  /// unsaved files.
  final FileContentOverlay contentOverlay;
  final ResourceProvider _resourceProvider;

  /* late final */ MoorSession session;
  StreamSubscription _fileChangeSubscription;
  StreamSubscription _taskCompleteSubscription;

  MoorDriver(this._tracker, this._scheduler, this.dartDriver,
      this.contentOverlay, this._resourceProvider,
      [MoorOptions options]) {
    _scheduler.add(this);
    final backend = CommonBackend(this);

    session = MoorSession(backend, options: options ?? const MoorOptions());
    ide = MoorIde(session, _DriverBasedFileManagement(this));

    _fileChangeSubscription =
        session.changedFiles.listen(_tracker.notifyFilesChanged);
    _taskCompleteSubscription =
        session.completedTasks.listen(_tracker.handleTaskCompleted);
  }

  bool _ownsFile(String path) =>
      path.endsWith('.moor') || path.endsWith('.dart');

  FoundFile pathToFoundFile(String path) {
    final uri = _resourceProvider.pathContext.toUri(path);
    return session.registerFile(uri);
  }

  @override
  void addFile(String path) {
    if (_ownsFile(path)) {
      final file = pathToFoundFile(path);
      _potentiallyNewFile(file);
    }
  }

  @override
  void dispose() {
    _fileChangeSubscription?.cancel();
    _taskCompleteSubscription?.cancel();

    _scheduler.remove(this);
    dartDriver.dispose();
    _tracker.dispose();
  }

  void _potentiallyNewFile(FoundFile file) {
    if (!file.isParsed) {
      handleFileChanged(file.uri.path);
    }
  }

  void handleFileChanged(String path) {
    if (_ownsFile(path)) {
      session.notifyFileChanged(pathToFoundFile(path));
      _scheduler.notify(this);
    }
    // also notify the underlying Dart driver
    dartDriver.changeFile(path);
  }

  @override
  bool get hasFilesToAnalyze => _tracker.hasWork;

  @override
  Future<void> performWork() async {
    final mostImportantFile = _tracker.fileWithHighestPriority;
    if (mostImportantFile.file?.isAnalyzed ?? false) {
      Logger.root.fine('Blocked attempt to work on fully analyzed file');
      return;
    }
    final backendTask = _createTask(mostImportantFile.file.uri);

    try {
      final task = session.startTask(backendTask);
      await task.runTask();
      session.notifyTaskFinished(task);
    } catch (e, s) {
      Logger.root.warning(
          'Error while working on ${mostImportantFile.file.uri}', e, s);
      _tracker.removePending(mostImportantFile);
    }
  }

  String readFile(String path) {
    final overlay = contentOverlay[path];
    if (overlay != null) {
      return overlay;
    }

    final file = _resourceProvider.getFile(path);
    return file.exists ? file.readAsStringSync() : '';
  }

  Future<LibraryElement> resolveDart(String path) async {
    final result = await dartDriver.currentSession.getResolvedLibrary(path);
    return result.element;
  }

  Future<bool> isDartLibrary(String path) async {
    return await dartDriver.getSourceKind(path) == SourceKind.LIBRARY;
  }

  bool doesFileExist(String path) {
    return contentOverlay[path] != null ||
        _resourceProvider.getFile(path).exists;
  }

  /// Finds the absolute path of a [reference] url, optionally assuming that the
  /// [reference] appears in [base]. This supports both "package:"-based uris
  /// and relative imports.
  /// Returns null if the uri can't be parsed.
  String absolutePath(Uri reference, {Uri base}) {
    final factory = dartDriver.sourceFactory;
    final baseSource = base == null ? null : factory.forUri2(base);

    final source = factory.resolveUri(baseSource, reference.toString());
    return source?.fullName;
  }

  CommonTask _createTask(Uri uri) {
    return CommonTask(uri, this);
  }

  @override
  // ignore: avoid_setters_without_getters
  set priorityFiles(List<String> priorityPaths) {
    final found = priorityPaths.where(_ownsFile).map(pathToFoundFile);
    _tracker.setPriorityFiles(found);
  }

  @override
  AnalysisDriverPriority get workPriority {
    if (_tracker.hasWork) {
      final mostImportant = _tracker.fileWithHighestPriority;
      return mostImportant.currentPriority;
    } else {
      return AnalysisDriverPriority.nothing;
    }
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
      scheduleMicrotask(() {
        // Changing files propagate async, so wait a bit before notifying.
        _scheduler.notify(this);
      });

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
