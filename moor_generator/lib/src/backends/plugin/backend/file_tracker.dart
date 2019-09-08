import 'dart:async';

import 'package:collection/collection.dart';
import 'package:moor_generator/src/analyzer/session.dart';

int _compareByPriority(TrackedFile a, TrackedFile b) {
  final aPriority = a.currentPriority?.index ?? 0;
  final bPriority = b.currentPriority?.index ?? 0;
  return aPriority.compareTo(bPriority);
}

/// Keeps track of files that need to be analyzed by the moor plugin.
class FileTracker {
  PriorityQueue<TrackedFile> _pendingWork;
  final Map<String, TrackedFile> _trackedFiles = {};
  final Set<TrackedFile> _currentPriority = {};

  final StreamController<TrackedFile> _computations =
      StreamController.broadcast();

  /// Streams that emits a [TrackedFile] when it has been worked on
  /// successfully.
  Stream<TrackedFile> get computations => _computations.stream;

  FileTracker() {
    _pendingWork = PriorityQueue(_compareByPriority);
  }

  void _updateFile(TrackedFile file, Function(TrackedFile) update) {
    _pendingWork.remove(file);
    update(file);
    _pendingWork.add(file);
  }

  void _putInQueue(TrackedFile file) {
    _updateFile(file, (f) {
      // no action needed, insert with current priority.
    });
  }

  bool get hasWork => _pendingWork.isNotEmpty;
  TrackedFile get fileWithHighestPriority => _pendingWork.first;

  TrackedFile addFile(String path) {
    return _trackedFiles.putIfAbsent(path, () {
      final tracked = TrackedFile(path);
      _pendingWork.add(tracked);
      return tracked;
    });
  }

  void handleContentChanged(String path) {
    _putInQueue(addFile(path));
  }

  void setPriorityFiles(Iterable<String> priority) {
    // remove prioritized flag from existing files
    for (var file in _currentPriority) {
      _updateFile(file, (f) => f._prioritized = false);
    }
    _currentPriority
      ..clear()
      ..addAll(priority.map(addFile))
      ..forEach((file) {
        _updateFile(file, (f) => f._prioritized = true);
      });
  }

  void notifyFileChanged(String path) {
    final tracked = addFile(path);
    tracked._currentResult = null;
    _putInQueue(tracked);
  }

  Future<MoorTask> results(String path) async {
    final tracked = addFile(path);

    if (tracked._currentResult != null) {
      return tracked._currentResult;
    } else {
      final completer = Completer<MoorTask>();
      tracked._waiting.add(completer);
      return completer.future;
    }
  }

  void work(Future<MoorTask> Function(String path) worker) {
    if (_pendingWork.isNotEmpty) {
      final unit = _pendingWork.removeFirst();

      worker(unit.path).then((result) {
        _computations.add(unit);

        for (var completer in unit._waiting) {
          completer.complete(result);
        }
        unit._waiting.clear();
      }, onError: (e, StackTrace s) {
        for (var completer in unit._waiting) {
          completer.completeError(e, s);
        }
        unit._waiting.clear();
      });
    }
  }

  void dispose() {
    _computations.close();
  }
}

enum FileType { moor, unknown }

enum FilePriority { ignore, regular, interactive }

const Map<FileType, FilePriority> _defaultPrio = {
  FileType.moor: FilePriority.regular,
  FileType.unknown: FilePriority.ignore,
};

class TrackedFile {
  final String path;
  final FileType type;

  /// Whether this file has been given an elevated priority, for instance
  /// because the user is currently typing in it.
  bool _prioritized = false;
  MoorTask _currentResult;
  final List<Completer<MoorTask>> _waiting = [];

  FilePriority get currentPriority =>
      _prioritized ? FilePriority.interactive : defaultPriority;

  TrackedFile._(this.path, this.type);

  factory TrackedFile(String path) {
    final type = path.endsWith('.moor') ? FileType.moor : FileType.unknown;
    return TrackedFile._(path, type);
  }

  FilePriority get defaultPriority => _defaultPrio[type];
}
