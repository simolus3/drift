import 'dart:async';

// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriverPriority;
import 'package:collection/collection.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';

int _compareByPriority(TrackedFile a, TrackedFile b) {
  final aPriority = a.currentPriority?.index ?? 0;
  final bPriority = b.currentPriority?.index ?? 0;
  return aPriority.compareTo(bPriority);
}

/// Keeps track of files that need to be analyzed by the moor plugin.
class FileTracker {
  PriorityQueue<TrackedFile> _pendingWork;
  final Map<FoundFile, TrackedFile> _trackedFiles = {};
  final Set<TrackedFile> _currentPriority = {};

  final StreamController<TrackedFile> _computations =
      StreamController.broadcast();

  FileTracker() {
    _pendingWork = PriorityQueue(_compareByPriority);
  }

  void _notifyFilePriorityChanged(TrackedFile file) {
    _pendingWork.remove(file);

    // if a file is analyzed, we don't need to do anything with it. So don't add
    // it back into the queue
    if (!file.file.isAnalyzed) {
      _pendingWork.add(file);
    }
  }

  bool get hasWork => _pendingWork.isNotEmpty;
  TrackedFile get fileWithHighestPriority => _pendingWork.first;

  TrackedFile _addFile(FoundFile file) {
    return _trackedFiles.putIfAbsent(file, () {
      final tracked = TrackedFile(file);
      _pendingWork.add(tracked);
      return tracked;
    });
  }

  /// Notify the work tracker that the list of [files] has changed. It's enough
  /// if any of the files in the list has changed, the others are likely
  /// affected because they transitively import the changed file. This method
  /// assumes that the [FoundFile.state] in each file has already been adjusted.
  void notifyFilesChanged(List<FoundFile> files) {
    files.map(_addFile).forEach(_notifyFilePriorityChanged);
  }

  void setPriorityFiles(Iterable<FoundFile> priority) {
    // remove prioritized flag from existing files
    for (var file in _currentPriority) {
      file._prioritized = false;
      _notifyFilePriorityChanged(file);
    }
    _currentPriority
      ..clear()
      ..addAll(priority.map(_addFile))
      ..forEach((file) {
        file._prioritized = true;
        _notifyFilePriorityChanged(file);
      });
  }

  void handleTaskCompleted(Task task) {
    for (var file in task.analyzedFiles) {
      _notifyFilePriorityChanged(_addFile(file));
    }
  }

  void dispose() {
    _computations.close();
  }
}

class TrackedFile {
  final FoundFile file;

  /// Whether this file has been given an elevated priority, for instance
  /// because the user is currently typing in it.
  bool _prioritized = false;

  AnalysisDriverPriority get currentPriority {
    if (_prioritized) {
      return file.state == FileState.dirty
          ? AnalysisDriverPriority.interactive
          : AnalysisDriverPriority.priority;
    } else if (file.state == FileState.analyzed) {
      return AnalysisDriverPriority.general;
    } else if (file.state == FileState.parsed) {
      return AnalysisDriverPriority.generalImportChanged;
    } else {
      return AnalysisDriverPriority.changedFiles;
    }
  }

  TrackedFile(this.file);
}
