import 'dart:async';

// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriverPriority;
import 'package:collection/collection.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';

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

  void _updateFile(TrackedFile file, Function(TrackedFile) update) {
    _pendingWork.remove(file);
    update(file);

    // if a file is analyzed, we don't need to do anything. So don't add it to
    // list of of tracked files.
    if (!file.file.isAnalyzed) {
      _pendingWork.add(file);
    }
  }

  void _putInQueue(TrackedFile file) {
    _updateFile(file, (f) {
      // no action needed, insert with current priority.
    });
  }

  bool get hasWork => _pendingWork.isNotEmpty;
  TrackedFile get fileWithHighestPriority => _pendingWork.first;

  void notifyAnalysisStateChanged(FoundFile file) {
    _putInQueue(_addFile(file));
  }

  TrackedFile _addFile(FoundFile file) {
    return _trackedFiles.putIfAbsent(file, () {
      final tracked = TrackedFile(file);
      _pendingWork.add(tracked);
      return tracked;
    });
  }

  void setPriorityFiles(Iterable<FoundFile> priority) {
    // remove prioritized flag from existing files
    for (var file in _currentPriority) {
      _updateFile(file, (f) => f._prioritized = false);
    }
    _currentPriority
      ..clear()
      ..addAll(priority.map(_addFile))
      ..forEach((file) {
        _updateFile(file, (f) => f._prioritized = true);
      });
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
