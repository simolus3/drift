import 'dart:async';

/// Signature of a function that returns the latest current value of a
/// [StartWithValueTransformer].
typedef LatestValue<T> = T Function();

/// Lightweight implementation that turns a [StreamController] into a behavior
/// subject (we try to avoid depending on rxdart because of its size).
class StartWithValueTransformer<T> extends StreamTransformerBase<T, T> {
  final LatestValue<T> _value;

  /// Constructs a stream transformer that will emit what's returned by [_value]
  /// to new listeners.
  StartWithValueTransformer(this._value);

  @override
  Stream<T> bind(Stream<T> stream) {
    // we're setting sync to true because we're proxying events
    final controller = StreamController<T>.broadcast(sync: true);

    // ignore: cancel_subscriptions
    StreamSubscription subscription;

    controller
      ..onListen = () {
        // Dart's stream contract specifies that listeners are only notified
        // after the .listen() code completes. So, we add the initial data in
        // a later microtask.
        scheduleMicrotask(() {
          final data = _value();
          if (data != null) {
            controller.add(data);
          }
        });

        // the .listen will run in a later microtask, so the cached data would
        // still be added first.
        subscription = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      }
      ..onCancel = () {
        // not using a tear-off here because subscription.cancel is null before
        // onListen has been called
        subscription?.cancel();
      };

    return controller.stream;
  }
}
