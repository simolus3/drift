// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/backends/plugin/backend/file_tracker.dart';
import 'package:moor_generator/src/backends/plugin/backend/plugin_backend.dart';

class MoorDriver implements AnalysisDriverGeneric {
  final FileTracker _tracker;

  final AnalysisDriverScheduler _scheduler;
  final AnalysisDriver dartDriver;

  /// The content overlay exists so that we can perform up-to-date analysis on
  /// unsaved files.
  final FileContentOverlay contentOverlay;
  final ResourceProvider _resourceProvider;

  final MoorSession session = MoorSession();

  MoorDriver(this._tracker, this._scheduler, this.dartDriver,
      this.contentOverlay, this._resourceProvider) {
    _scheduler.add(this);
  }

  bool _ownsFile(String path) => path.endsWith('.moor');

  @override
  void addFile(String path) {
    if (_ownsFile(path)) {
      _tracker.addFile(path);
    }
  }

  @override
  void dispose() {
    _scheduler.remove(this);
    dartDriver.dispose();
  }

  void handleFileChanged(String path) {
    if (_ownsFile(path)) {
      _tracker.handleContentChanged(path);
      _scheduler.notify(this);
    }
  }

  @override
  bool get hasFilesToAnalyze => _tracker.hasWork;

  @override
  Future<void> performWork() async {
    final completer = Completer();

    if (_tracker.hasWork) {
      _tracker.work((path) async {
        try {
          final backendTask = _createTask(path);
          final moorTask = await session.startMoorTask(backendTask);
          await moorTask.compute();

          return moorTask;
        } finally {
          completer.complete();
        }
      });

      await completer.future;
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

  /// Finds the absolute path of a [reference] url, optionally assuming that the
  /// [reference] appears in [base]. This supports both "package:"-based uris
  /// and relative imports.
  String absolutePath(Uri reference, {Uri base}) {
    final factory = dartDriver.sourceFactory;
    final baseSource = base == null ? null : factory.forUri2(base);

    final source =
        dartDriver.sourceFactory.resolveUri(baseSource, reference.toString());
    return source.fullName;
  }

  PluginTask _createTask(String path) {
    final uri = Uri.parse(path).replace(scheme: 'file');
    return PluginTask(uri, this);
  }

  @override
  set priorityFiles(List<String> priorityPaths) {
    _tracker.setPriorityFiles(priorityPaths.where(_ownsFile));
  }

  @override
  AnalysisDriverPriority get workPriority {
    if (_tracker.hasWork) {
      final mostImportant = _tracker.fileWithHighestPriority;
      switch (mostImportant.currentPriority) {
        case FilePriority.ignore:
          return AnalysisDriverPriority.nothing;
        case FilePriority.regular:
          return AnalysisDriverPriority.general;
        case FilePriority.interactive:
          return AnalysisDriverPriority.interactive;
      }
    } else {
      return AnalysisDriverPriority.nothing;
    }
    throw AssertionError('unreachable');
  }

  Future<MoorTask> parseMoorFile(String path) {
    _scheduler.notify(this);
    return _tracker.results(path);
  }
}
