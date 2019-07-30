// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:moor_generator/src/plugin/state/file_tracker.dart';

import 'analyzer/moor_analyzer.dart';
import 'analyzer/results.dart';

class MoorDriver implements AnalysisDriverGeneric {
  final FileTracker _tracker;
  final AnalysisDriverScheduler _scheduler;
  final MoorAnalyzer _analyzer;
  final ResourceProvider _resources;

  MoorDriver(this._tracker, this._scheduler, this._analyzer, this._resources) {
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
      _tracker.work((path) {
        try {
          return _resolveMoorFile(path);
        } finally {
          completer.complete();
        }
      });

      await completer.future;
    }
  }

  Future<MoorAnalysisResults> _resolveMoorFile(String path) {
    return _analyzer.analyze(_resources.getFile(path));
  }

  @override
  set priorityFiles(List<String> priorityPaths) {
    _tracker.setPriorityFiles(priorityPaths);
  }

  @override
  // todo ask the tracker about the top-priority file.
  AnalysisDriverPriority get workPriority => AnalysisDriverPriority.general;

  Future<MoorAnalysisResults> parseMoorFile(String path) {
    _scheduler.notify(this);
    return _tracker.results(path);
  }
}
