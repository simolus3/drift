import 'dart:convert';
import 'dart:io';

import 'package:benchmarks/benchmarks.dart';

final File output = File('benchmark_results.json');

void main() {
  final tracker = TrackingEmitter();
  ComparingEmitter comparer;
  if (output.existsSync()) {
    final content = json.decode(output.readAsStringSync());
    final oldData = (content as Map).cast<String, double>();
    comparer = ComparingEmitter(oldData);
  } else {
    comparer = ComparingEmitter();
  }

  final emitter = MultiEmitter([tracker, comparer]);
  final benchmarks = allBenchmarks(emitter);

  for (final benchmark in benchmarks) {
    benchmark.report();
  }

  output.writeAsStringSync(json.encode(tracker.timings));
}
