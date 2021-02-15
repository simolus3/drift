import 'dart:async';

/// A single asynchronous lock implemented by future-chaining.
class Lock {
  Future<void> _last = Future.value();

  /// Waits for previous [synchronized]-calls on this [Lock] to complete, and
  /// then calls [block] before further [synchronized] calls are allowed.
  Future<T> synchronized<T>(FutureOr<T> Function() block) {
    final previous = _last;
    // We can use synchronous futures for _last since we always complete through
    // callBlockAndComplete(), which is asynchronous.
    final blockCompleted = Completer<void>.sync();
    _last = blockCompleted.future;

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
