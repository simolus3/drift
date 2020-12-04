import 'dart:async';

/// Transforms a stream of lists into a stream of single elements, assuming
/// that each list is a singleton.
StreamTransformer<List<T>, T?> singleElements<T>() {
  return StreamTransformer.fromHandlers(handleData: (data, sink) {
    try {
      if (data.isEmpty) {
        sink.add(null);
      } else {
        sink.add(data.single);
      }
    } catch (e) {
      sink.addError(
          StateError('Expected exactly one element, but got ${data.length}'));
    }
  });
}
