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
  bool get isBroadcast => _inner.isBroadcast;

  @override
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    // We do cancel this subscription when the wrapper is cancelled.
    // ignore: cancel_subscriptions
    final subscription = _inner.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);

    final data = _value();
    return _StartWithValueSubscription(subscription, data, onData);
  }
}

class _StartWithValueSubscription<T> extends StreamSubscription<T> {
  final StreamSubscription<T> _inner;
  final T initialData;

  bool receivedDataFromInner = false;
  void Function(T data) _onData;

  _StartWithValueSubscription(this._inner, this.initialData, this._onData) {
    // Dart's stream contract specifies that listeners are only notified
    // after the .listen() code completes. So, we add the initial data in
    // a later microtask.
    if (initialData != null) {
      scheduleMicrotask(() {
        if (!receivedDataFromInner) {
          _onData?.call(initialData);
          receivedDataFromInner = true;
        }
      });
    }
  }

  @override
  Future<E> asFuture<E>([E futureValue]) => _inner.asFuture();

  @override
  Future<void> cancel() => _inner.cancel();

  @override
  bool get isPaused => _inner.isPaused;

  @override
  void onData(void Function(T data) handleData) {
    print('onData called');
    _onData = handleData;

    void wrappedCallback(T event) {
      receivedDataFromInner = true;
      handleData?.call(event);
    }

    _inner.onData(wrappedCallback);
  }

  @override
  void onDone(void Function() handleDone) => _inner.onDone(handleDone);

  @override
  void onError(Function handleError) => _inner.onError(handleError);

  @override
  void pause([Future<void> resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();
}
