import 'dart:async';

import 'package:benchmarks/benchmarks.dart';
import 'package:test/test.dart';

void main() {
  test('compares time for increase', () {
    final comparer = ComparingEmitter({'foo': 10.0});
    final output = printsOf(() => comparer.emit('foo', 12.5));
    expect(output, ['foo: 12.5 us; delta: +2.5 us, +25%']);
  });

  test('compares time for decrease', () {
    final comparer = ComparingEmitter({'foo': 10.0});
    final output = printsOf(() => comparer.emit('foo', 7.5));
    expect(output, ['foo: 7.5 us; delta: -2.5 us, -25%']);
  });

  test('no comparison when old value unknown', () {
    final comparer = ComparingEmitter();
    final output = printsOf(() => comparer.emit('foo', 10));
    expect(output, ['foo: 10.0 us']);
  });
}

List<String> printsOf(Function() code) {
  final output = <String>[];

  runZoned(
    code,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) => output.add(line),
    ),
  );

  return output;
}
