import 'dart:async';
import 'dart:collection';

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';

import 'driver.dart';

const _lowestPriority = AnalysisDriverPriority.general;

/// Analysis in the plugin is performed by two drivers: The [MoorDriver] and the
/// builtin [AnalysisDriver] from the analyzer. A [AnalysisDriverScheduler] is
/// responsible to make these drivers perform work.
///
/// We can hit a deadlock in that system when we need to analyze a Dart file as
/// part of a moor file, because the flow will look like
///
/// 1. the scheduler instructs the moor driver to analyze a moor file
/// 2. that file contains a Dart import, we wait for the Dart driver to resolve
///    that library
/// 3. The Dart driver never gets called because the moor driver isn't done yet,
///    we hit a deadlock.
///
/// This class is responsible for resolving those deadlocks by pausing the moor
/// driver and and decreasing its priority. This will make the scheduler call
/// the dart driver instead and resolve step two. When that's done, we will
/// continue our work.
class DriverSynchronizer {
  _WorkUnit _currentUnit;
  Completer _waitForResume;

  /// Whether analyzing a moor file was paused to resolve a deadlock
  bool get hasPausedWork => _waitForResume != null;

  /// If this synchronizer [hasPausedWork], returns the changed priority that
  /// should be reported to the scheduler so that the analysis driver is called
  /// first. Otherwise returns `null`.
  AnalysisDriverPriority get overriddenPriority {
    return hasPausedWork ? _lowestPriority : null;
  }

  Future<T> useDartDriver<T>(Future<T> Function() action) {
    assert(_currentUnit != null && _waitForResume == null,
        'Dart driver can only be used as a part of a non-paused task');
    _waitForResume = Completer();
    // make safeRunTask or resume complete, so that work is delegated to the
    // dart driver
    _currentUnit._completeCurrentStep();

    return action().then((value) async {
      await _waitForResume.future;
      _waitForResume = null;
      return value;
    });
  }

  Future<void> resumePaused() {
    assert(hasPausedWork);

    _waitForResume.complete();
    return _currentUnit._currentCompleter.future;
  }

  Future<void> safeRunTask(Task task) async {
    assert(!hasPausedWork, "Can't start a new task, another one was paused");
    _currentUnit = _WorkUnit()..task = task;

    await task.runTask();
    _handleTaskCompleted(task);

    return _currentUnit._currentCompleter.future;
  }

  void _handleTaskCompleted(Task task) {
    assert(_currentUnit.task == task, 'Finished an unexpected task');
    _currentUnit._currentCompleter.complete();
  }
}

class _WorkUnit extends LinkedListEntry<_WorkUnit> {
  Task task;
  Completer _currentCompleter = Completer();

  void _completeCurrentStep() {
    _currentCompleter.complete();
    _currentCompleter = Completer();
  }
}
