import 'dart:async';

import 'package:drift/src/utils/start_with_value_transformer.dart';
import 'package:test/test.dart';

void main() {
  /// Create a stream emitting a single event after one event loop iteration.
  Stream streamForTests() {
    return Stream.fromFuture(Future.delayed(Duration.zero, () => 1));
  }

  test('emits initial data after one microtask', () {
    final stream =
        streamForTests().transform(StartWithValueTransformer(() => 0));

    final events = [];
    stream.listen(events.add);
    expect(events, isEmpty);

    final testCompleter = Completer();
    scheduleMicrotask(() {
      expect(events, isNotEmpty);
      expect(events.first, 0);
      testCompleter.complete();
    });

    // Don't finish the test until the microtask fired
    return testCompleter.future;
  });

  test('does not emit data if the source stream is faster', () {
    final stream = Future.sync(() => 1)
        .asStream()
        .transform(StartWithValueTransformer(() => 0));

    expect(stream.first, completion(1));
  });

  group('does not emit initial data', () {
    test('if the subscription was cancelled', () async {
      final stream =
          streamForTests().transform(StartWithValueTransformer(() => 0));

      final events = [];
      await stream.listen(events.add).cancel();

      await pumpEventQueue();
      expect(events, isEmpty);
    });

    test('if the subscription is paused', () async {
      final stream =
          streamForTests().transform(StartWithValueTransformer(() => 0));

      final events = [];
      stream.listen(events.add).pause();

      await pumpEventQueue();
      expect(events, isEmpty);
    });
  });
}
