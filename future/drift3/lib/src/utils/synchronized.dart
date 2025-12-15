import 'dart:async';

import 'package:meta/meta.dart';

/// A single asynchronous lock implemented by future-chaining.
final class Lock {
  Future<void>? _last;

  /// Waits for previous [synchronized]-calls on this [Lock] to complete, and
  /// then calls [block] before further [synchronized] calls are allowed.
  Future<T> synchronized<T>(FutureOr<T> Function() block) {
    final previous = _last;
    // This completer may not be sync: It must complete just after
    // callBlockAndComplete completes.
    final blockCompleted = Completer<void>();
    final blockReleasedLock = blockCompleted.future;
    _last = blockReleasedLock;

    Future<T> callBlockAndComplete() {
      return Future.sync(block).whenComplete(() {
        blockCompleted.complete();

        if (identical(_last, blockReleasedLock)) {
          // There's no subsequent waiter entering the lock now, so we can reset
          // the entire state.
          _last = null;

          // This doesn't affect the correctness of the lock, but is helpful
          // when drift is used in `fake_async` scenarios but then cleaned up
          // outside of that `fake_async` scope (a very common pattern in
          // Flutter widget tests).
          // Waiting on `previous.then` on a completed `previous` future will
          // schedule a microtask, so if we call synchronized in a zone outside
          // of fake_async and the lock was previously locked in a fake_async
          // zone, that microtask might not run if no one completes the pending
          // fake_async microtasks.
          // Since the lock is idle anyway, the next waiter can just call
          // callBlockAndComplete() directly without calling `.then()` on a
          // future that will no longer notify listeners.
        }
      });
    }

    if (previous != null) {
      return previous.then((_) => callBlockAndComplete());
    } else {
      return callBlockAndComplete();
    }
  }
}

@internal
final class SharedOrExclusiveLock {
  int _shared = 0;
  bool _hasExclusiveLock = false;

  final List<void Function()> _exclusiveWaiters = [];

  Future<void> _scheduleExclusive(void Function() action) {
    final completer = Completer<void>();
    _exclusiveWaiters.add(() {
      assert(_shared == 0 && !_hasExclusiveLock);
      action();
      assert(_shared > 0 || _hasExclusiveLock);

      completer.complete();
    });

    return completer.future;
  }

  Future<void> _obtainShared() {
    if (!_hasExclusiveLock && _exclusiveWaiters.isEmpty) {
      _shared++;
      return Future.value();
    } else {
      return _scheduleExclusive(() {
        _shared++;
      });
    }
  }

  Future<void> _obtainExclusive() {
    if (_shared == 0 && !_hasExclusiveLock) {
      _hasExclusiveLock = true;
      return Future.value();
    } else {
      return _scheduleExclusive(() {
        _hasExclusiveLock = true;
      });
    }
  }

  void _releaseShared() {
    assert(_shared > 0);
    _shared--;
    if (_shared == 0 && _exclusiveWaiters.isNotEmpty) {
      final waiter = _exclusiveWaiters.removeAt(0);
      waiter();
    }
  }

  void _releaseExclusive() {
    assert(_hasExclusiveLock);
    _hasExclusiveLock = false;
    if (_exclusiveWaiters.isNotEmpty) {
      final waiter = _exclusiveWaiters.removeAt(0);
      waiter();
    }
  }

  Future<T> _run<T>(bool exclusive, FutureOr<T> Function() block) async {
    await (exclusive ? _obtainExclusive() : _obtainShared());
    try {
      return await block();
    } finally {
      if (exclusive) {
        _releaseExclusive();
      } else {
        _releaseShared();
      }
    }
  }

  Future<T> shared<T>(FutureOr<T> Function() block) {
    return _run(false, block);
  }

  Future<T> exclusive<T>(FutureOr<T> Function() block) {
    return _run(true, block);
  }
}
