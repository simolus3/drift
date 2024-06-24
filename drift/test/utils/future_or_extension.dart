import 'dart:async';

extension FutureOrExt<T> on FutureOr<T> {
  Future<T> toFuture() {
    return this is Future<T> ? this as Future<T> : Future.value(this as T);
  }
}
