import 'dart:async';

/// Transforms a stream of lists into a stream of single elements, assuming
/// that each list is a singleton or empty.
StreamTransformer<List<T>, T?> singleElementsOrNull<T>() {
  final originTrace = StackTrace.current;

  return StreamTransformer.fromHandlers(handleData: (data, sink) {
    T? result;

    try {
      if (data.isNotEmpty) {
        result = data.single;
      }
    } catch (e) {
      Error.throwWithStackTrace(
          StateError('Expected exactly one element, but got ${data.length}'),
          originTrace);
    }

    sink.add(result);
  });
}

/// Transforms a stream of lists into a stream of single elements, assuming
/// that each list is a singleton.
StreamTransformer<List<T>, T> singleElements<T>() {
  final originTrace = StackTrace.current;

  return StreamTransformer.fromHandlers(handleData: (data, sink) {
    T single;

    try {
      single = data.single;
    } catch (e) {
      Error.throwWithStackTrace(
          StateError('Expected exactly one element, but got ${data.length}'),
          originTrace);
    }

    sink.add(single);
  });
}
