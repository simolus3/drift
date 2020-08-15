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
    final data = _value();
    return _StartWithValueSubscription(_inner, data, onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class _StartWithValueSubscription<T> extends StreamSubscription<T> {
  StreamSubscription<T> _inner;
  final T initialData;

  bool needsInitialData = true;
  void Function(T data) _onData;

  _StartWithValueSubscription(
      Stream<T> innerStream, this.initialData, this._onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    _inner = innerStream.listen(_wrappedDataCallback(_onData),
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);

    // Dart's stream contract specifies that listeners are only notified
    // after the .listen() code completes. So, we add the initial data in
    // a later microtask.
    if (initialData != null) {
      scheduleMicrotask(() {
        if (needsInitialData) {
          _onData?.call(initialData);
          needsInitialData = false;
        }
      });
    }
  }

  void Function(T data) _wrappedDataCallback(void Function(T data) onData) {
    return (event) {
      needsInitialData = false;
      onData?.call(event);
    };
  }

  @override
  Future<E> asFuture<E>([E futureValue]) => _inner.asFuture();

  @override
  Future<void> cancel() {
    needsInitialData = false;
    return _inner.cancel();
  }

  @override
  bool get isPaused => _inner.isPaused;

  @override
  void onData(void Function(T data) handleData) {
    _onData = handleData;

    _inner.onData(_wrappedDataCallback(handleData));
  }

  @override
  void onDone(void Function() handleDone) => _inner.onDone(handleDone);

  @override
  void onError(Function handleError) => _inner.onError(handleError);

  @override
  void pause([Future<void> resumeSignal]) {
    needsInitialData = false;
    _inner.pause(resumeSignal);
  }

  @override
  void resume() => _inner.resume();
}
