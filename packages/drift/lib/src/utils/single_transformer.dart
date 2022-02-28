import 'dart:async';

/// Transforms a stream of lists into a stream of single elements, assuming
/// that each list is a singleton or empty.
StreamTransformer<List<T>, T?> singleElementsOrNull<T>() {
  return StreamTransformer.fromHandlers(handleData: (data, sink) {
    T? result;

    try {
      if (data.isNotEmpty) {
        result = data.single;
      }
    } catch (e) {
      throw StateError('Expected exactly one element, but got ${data.length}');
    }

    sink.add(result);
  });
}

/// Transforms a stream of lists into a stream of single elements, assuming
/// that each list is a singleton.
StreamTransformer<List<T>, T> singleElements<T>() {
  return StreamTransformer.fromHandlers(handleData: (data, sink) {
    T single;

    try {
      single = data.single;
    } catch (e) {
      throw StateError('Expected exactly one element, but got ${data.length}');
    }

    sink.add(single);
  });
}
