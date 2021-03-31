import 'dart:async';

import 'package:meta/meta.dart';

const _key = #moor.runtime.cancellation;

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
    (error, trace) {
      final completer = token._resultCompleter;

      if (error is CancellationException) {
        completer.complete(null);
      } else {
        completer.completeError(error, trace);
      }
    },
    zoneValues: {_key: token},
  );

  return token;
}

/// A token that can be used to cancel an asynchronous operation running in a
/// child zone.
@internal
class CancellationToken<T> {
  final Completer<T?> _resultCompleter = Completer.sync();
  bool _cancellationRequested = false;

  /// Loads the result for the cancellable operation.
  ///
  /// When the operation is cancelled, the future might complete with `null`.
  Future<T?> get result => _resultCompleter.future;

  /// Requests the inner asynchronous operation to be cancelled.
  void cancel() => _cancellationRequested = true;
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
