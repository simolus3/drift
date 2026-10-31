import 'dart:async';

/// An abort signal for drift queries.
///
/// Instances of this can be passed to most drift methods operating on the
/// database. For query streams, cancelling the stream subscription makes drift
/// abort individual queries through the same mechanism.
final class AbortToken {
  final _completer = Completer<void>();

  /// Creates a new abort token.
  ///
  /// If the [parent] future is set, this token aborts when it completes. Errors
  /// on that future are unhandled.
  AbortToken([Future<void>? parent]) {
    if (parent != null) {
      parent.whenComplete(abort);
    }
  }

  /// Whether this token has been aborted.
  bool get isAborted => _completer.isCompleted;

  /// A future that completes once this token has been aborted.
  Future<void> get aborted => _completer.future;

  /// Aborts this token.
  ///
  /// Drift queries receiving this token may react by throwing an
  /// [AbortException] instead of completing regularly, which can be caught with
  /// [catchAbortExceptions]. Futures returned by those methods must still be
  /// awaited.
  void abort() {
    if (!isAborted) {
      _completer.complete();
    }
  }

  /// Throws an [AbortException] if this token has been aborted.
  void checkAborted() {
    if (isAborted) throw const AbortException();
  }

  /// Catches abort errors from the [original] future.
  ///
  /// This is different from a plain `on AbortException` catch block as it only
  /// catches abort exceptions when this token has actually been aborted.
  ///
  /// To turn abort errors into null returns, use the [orNullIfAborted] helper.
  Future<T> catchAbortExceptions<T>(
    Future<T> original,
    T Function() onAborted,
  ) {
    return original.onError<AbortException>(
      (_, _) => onAborted(),
      test: (_) => isAborted,
    );
  }

  /// Returns a future completing with [original], replacing abort exceptions
  /// from this abort token with null.
  Future<T?> orNullIfAborted<T extends Object>(Future<T> original) {
    return catchAbortExceptions<T?>(original, () => null);
  }
}

/// Thrown when an asynchronous operation has been aborted by an [AbortToken].
///
/// Drift throws this exception internally to cancel an ongoing operation, e.g.
/// to save resources when a query stream subscription is canceled while drift
/// is preparing to run its statement.
final class AbortException implements Exception {
  /// Default const constructor
  const AbortException();

  @override
  String toString() {
    return 'Operation was abort';
  }
}
