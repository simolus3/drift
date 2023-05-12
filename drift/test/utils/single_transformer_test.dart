import 'dart:async';

import 'package:drift/src/utils/single_transformer.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

void main() {
  test('transforms simple values', () {
    final controller = StreamController<List<int>>();
    final stream = controller.stream.transform(singleElements());

    expectLater(stream, emitsInOrder([1, 2, 3, 4]));

    controller
      ..add([1])
      ..add([2])
      ..add([3])
      ..add([4]);
    controller.close();
  });

  test('emits errors for invalid lists', () {
    final controller = StreamController<List<int>>();
    final stream = controller.stream.transform(singleElements());

    expectLater(
      stream,
      emitsInOrder([
        1,
        emitsError(_stateErrorWithTrace),
        2,
        emitsError(_stateErrorWithTrace)
      ]),
    );

    controller
      ..add([1])
      ..add([2, 3])
      ..add([2])
      ..add([]);
    controller.close();
  });

  test('singleElementsOrNull() emits null for empty data', () {
    final stream = Stream.value(<Object?>[]);
    expect(stream.transform(singleElementsOrNull()), emits(isNull));
  });

  test('stack traces reflect where the transformer was created', () {
    final controller = StreamController<List<int>>();
    final stream = controller.stream.transform(singleElements());

    final error = isStateError.having(
      (e) => e.stackTrace,
      'stackTrace',
      // Make sure that the predicate points to where the transformation was
      // applied instead of just containing asynchronous gaps and drift-internal
      // frames.
      predicate((trace) {
        final parsed = Trace.from(trace as StackTrace);

        return parsed.frames.any(
          (f) =>
              f.uri.path.contains('single_transformer_test.dart') &&
              f.line == 51,
        );
      }),
    );

    expectLater(
      stream,
      emitsInOrder([
        1,
        emitsError(error),
        2,
        emitsDone,
      ]),
    );

    controller
      ..add([1])
      ..add([2, 3])
      ..add([2])
      ..close();
  }, testOn: 'vm');
}

Matcher _stateErrorWithTrace =
    isStateError.having((e) => e.stackTrace, 'stackTrace', isNotNull);
