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
  final PriorityQueue<TrackedFile> _pendingWork =
      PriorityQueue(_compareByPriority);
  final Map<FoundFile, TrackedFile> _trackedFiles = {};
  final Set<TrackedFile> _currentPriority = {};

  final StreamController<TrackedFile> _computations =
      StreamController.broadcast();

  void _changeFilePriority(TrackedFile file, Function() action) {
    _pendingWork.remove(file);

    action();

    // if a file is analyzed, we don't need to do anything with it. So don't add
    // it back into the queue
    if (!file.file.isAnalyzed) {
      _pendingWork.add(file);
    }
  }

  bool get hasWork => _pendingWork.isNotEmpty;
  TrackedFile get fileWithHighestPriority =>
      hasWork ? _pendingWork.first : null;

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
  void notifyFilesChanged(Iterable<FoundFile> files) {
    files.map(_addFile).forEach((file) {
      _changeFilePriority(file, file._adjustPriorityOnCurrentState);
    });
  }

  void setPriorityFiles(Iterable<FoundFile> priority) {
    // remove prioritized flag from existing files
    for (final file in _currentPriority) {
      _changeFilePriority(file, () {
        file._prioritized = false;
      });
    }
    _currentPriority
      ..clear()
      ..addAll(priority.map(_addFile))
      ..forEach((file) {
        _changeFilePriority(file, () {
          file._prioritized = true;
        });
      });
  }

  void handleTaskCompleted(Task task) {
    notifyFilesChanged(task.analyzedFiles);
  }

  /// Manually remove the [file] from the backlog. As the plugin is still very
  /// unstable, we use this on unexpected errors so that we just move on to the
  /// next file if there is a problem.
  void removePending(TrackedFile file) {
    _pendingWork.remove(file);
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

  // for the priority queue to work, we can only change the priority in
  // _changeFilePriority.
  AnalysisDriverPriority _cachedPriority;

  AnalysisDriverPriority get currentPriority {
    return _cachedPriority;
  }

  void _adjustPriorityOnCurrentState() {
    if (_prioritized) {
      _cachedPriority = file.state == FileState.dirty
          ? AnalysisDriverPriority.interactive
          : AnalysisDriverPriority.priority;
    } else if (file.state == FileState.analyzed) {
      _cachedPriority = AnalysisDriverPriority.nothing;
    } else if (file.state == FileState.parsed) {
      _cachedPriority = AnalysisDriverPriority.generalImportChanged;
    } else {
      _cachedPriority = AnalysisDriverPriority.changedFiles;
    }
  }

  TrackedFile(this.file) {
    // initialize _cachedPriority
    _adjustPriorityOnCurrentState();
  }
}
