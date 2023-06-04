import 'dart:async';

/// Extension to make the drift-specific version of [asyncMap] available.
extension AsyncMapPerSubscription<S> on Stream<S> {
  /// A variant of [Stream.asyncMap] that forwards each subscription of the
  /// returned stream to the source (`this`).
  ///
  /// The `asyncMap` implementation from the SDK uses a broadcast controller
  /// when given an input stream that [Stream.isBroadcast]. As broadcast
  /// controllers only call `onListen` once, these subscriptions aren't
  /// forwarded to the original stream.
  ///
  /// Drift query streams send the current snapshot to each attaching listener,
  /// a behavior that is lost when wrapping these streams in a broadcast stream
  /// controller. Since we need the behavior of `asyncMap` internally though, we
  /// re-implement it in a simple variant that transforms each subscription
  /// individually.
  Stream<T> asyncMapPerSubscription<T>(Future<T> Function(S) mapper) {
    return Stream.multi(
      (listener) {
        late StreamSubscription<S> subscription;

        void onData(S original) {
          subscription.pause();
          mapper(original)
              .then(listener.addSync, onError: listener.addErrorSync)
              .whenComplete(subscription.resume);
        }

        subscription = listen(
          onData,
          onError: listener.addErrorSync,
          onDone: listener.closeSync,
          cancelOnError: false, // Determined by downstream subscription
        );

        listener
          ..onPause = subscription.pause
          ..onResume = subscription.resume
          ..onCancel = subscription.cancel;
      },
      isBroadcast: isBroadcast,
    );
  }
}
