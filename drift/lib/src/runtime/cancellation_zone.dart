import 'dart:async';

import 'package:meta/meta.dart';

const _key = #drift.runtime.cancellation;

/// Runs an asynchronous operation with support for cancellations.
///
/// The [CancellationToken] can be used to cancel the operation and to get the
/// eventual result.
CancellationToken<T> runCancellable<T>(
  Future<T> Function() operation,
) {
  final token = CancellationToken<T>();
  runZonedGuarded(
    () => operation().then(token._resultCompleter.complete),
    token._resultCompleter.completeError,
    zoneValues: {_key: token},
  );

  return token;
}

/// A token that can be used to cancel an asynchronous operation running in a
/// child zone.
@internal
class CancellationToken<T> {
  final Completer<T> _resultCompleter = Completer.sync();
  final List<void Function()> _cancellationCallbacks = [];
  bool _cancellationRequested = false;

  /// Loads the result for the cancellable operation.
  ///
  /// When a cancellation has been requested and was honored, the future will
  /// complete with a [CancellationException].
  Future<T> get result => _resultCompleter.future;

  /// Requests the inner asynchronous operation to be cancelled.
  void cancel() {
    if (_cancellationRequested) return;

    for (final callback in _cancellationCallbacks) {
      callback();
    }
    _cancellationRequested = true;
  }
}

/// Extensions that can be used on cancellable operations if they return a non-
/// nullable value.
extension NonNullableCancellationExtension<T extends Object>
    on CancellationToken<T> {
  /// Wait for the result, or return `null` if the operation was cancelled.
  ///
  /// To avoid situations where `null` could be a valid result from an async
  /// operation, this getter is only available on non-nullable operations. This
  /// avoids ambiguity.
  ///
  /// The future will still complete with an error if anything but a
  /// [CancellationException] is thrown in [result].
  Future<T?> get resultOrNullIfCancelled async {
    try {
      return await result;
    } on CancellationException {
      return null;
    }
  }
}

/// Thrown inside a cancellation zone when it has been cancelled.
@internal
class CancellationException implements Exception {
  /// Default const constructor
  const CancellationException();

  @override
  String toString() {
    return 'Operation was cancelled';
  }
}

/// Checks whether the active zone is a cancellation zone that has been
/// cancelled. If it is, a [CancellationException] will be thrown.
void checkIfCancelled() {
  final token = Zone.current[_key];
  if (token is CancellationToken && token._cancellationRequested) {
    throw const CancellationException();
  }
}

/// Requests the [callback] to be invoked when the enclosing asynchronous
/// operation is cancelled.
void doOnCancellation(void Function() callback) {
  final token = Zone.current[_key];
  if (token is CancellationToken) {
    token._cancellationCallbacks.add(callback);
  }
}
