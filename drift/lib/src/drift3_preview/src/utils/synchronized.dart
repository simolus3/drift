import 'dart:async';

import 'package:meta/meta.dart';

import 'abort.dart';

@internal
final class SharedOrExclusiveLock {
  int _shared = 0;
  bool _hasExclusiveLock = false;

  final List<void Function()> _exclusiveWaiters = [];

  Future<void> _scheduleExclusive(void Function() action, AbortToken? abort) {
    final completer = Completer<void>();
    var didRun = false;

    void run() {
      didRun = true;
      assert(_shared == 0 && !_hasExclusiveLock);
      action();
      assert(_shared > 0 || _hasExclusiveLock);

      completer.complete();
    }

    _exclusiveWaiters.add(run);

    abort?.aborted.whenComplete(() {
      if (!didRun) {
        _exclusiveWaiters.remove(run);
        completer.completeError(const AbortException());
      }
    });

    return completer.future;
  }

  Future<void> _obtainShared(AbortToken? abort) {
    if (!_hasExclusiveLock && _exclusiveWaiters.isEmpty) {
      _shared++;
      return Future.value();
    } else {
      return _scheduleExclusive(() {
        _shared++;
      }, abort);
    }
  }

  Future<void> _obtainExclusive(AbortToken? abort) {
    if (_shared == 0 && !_hasExclusiveLock) {
      _hasExclusiveLock = true;
      return Future.value();
    } else {
      return _scheduleExclusive(() {
        _hasExclusiveLock = true;
      }, abort);
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

  Future<T> _run<T>(
    bool exclusive,
    FutureOr<T> Function() block,
    AbortToken? abort,
  ) async {
    abort?.checkAborted();
    await (exclusive ? _obtainExclusive(abort) : _obtainShared(abort));
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

  Future<T> shared<T>(FutureOr<T> Function() block, [AbortToken? abort]) {
    return _run(false, block, abort);
  }

  Future<T> exclusive<T>(FutureOr<T> Function() block, [AbortToken? abort]) {
    return _run(true, block, abort);
  }
}
