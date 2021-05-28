import 'dart:async';

/// A single asynchronous lock implemented by future-chaining.
class Lock {
  Future<void> _last = Future.value();

  /// Waits for previous [synchronized]-calls on this [Lock] to complete, and
  /// then calls [block] before further [synchronized] calls are allowed.
  Future<T> synchronized<T>(FutureOr<T> Function() block) {
    final previous = _last;
    // This controller may not be sync: It must complete just after
    // callBlockAndComplete completes.
    final blockCompleted = Completer<void>();
    _last = blockCompleted.future;

    // Note: We can't use async/await here because this future must complete
    // just before the blockCompleted completer.
    Future<T> callBlockAndComplete() async {
      try {
        return await block();
      } finally {
        blockCompleted.complete();
      }
    }

    return previous.then((_) => callBlockAndComplete());
  }
}
