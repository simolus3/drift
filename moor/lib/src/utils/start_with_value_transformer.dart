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
    return _StartWithValueStream(_value, stream);
  }
}

class _StartWithValueStream<T> extends Stream<T> {
  final LatestValue<T> _value;
  final Stream<T> _inner;

  _StartWithValueStream(this._value, this._inner);

  @override
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    var didReceiveData = false;
    void wrappedCallback(T event) {
      didReceiveData = true;
      onData?.call(event);
    }

    final subscription = _inner.listen(wrappedCallback,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);

    final data = _value();
    // Dart's stream contract specifies that listeners are only notified
    // after the .listen() code completes. So, we add the initial data in
    // a later microtask.
    scheduleMicrotask(() {
      if (data != null && !didReceiveData) {
        onData?.call(data);
        didReceiveData = true;
      }
    });

    return subscription;
  }
}
