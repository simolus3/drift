@internal
import 'dart:async';

import 'package:meta/meta.dart';

/// Drift-internal utilities to map potentially async operations.
extension MapAndAwait<T> on Iterable<T> {
  /// A variant of [Future.wait] that also works for [FutureOr].
  FutureOr<List<R>> mapAsyncAndAwait<R>(FutureOr<R> Function(T) mapper) {
    if (mapper is R Function(T)) {
      // It's actually all synchronous
      return map(mapper).toList();
    }

    return Future.wait(map((e) => Future.sync(() => mapper(e))));
  }
}
