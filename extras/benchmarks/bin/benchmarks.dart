import 'dart:convert';
import 'dart:io';

import 'package:benchmarks/benchmarks.dart';

final File output = File('benchmark_results.json');

Future<void> main() async {
  final tracker = TrackingEmitter();
  ComparingEmitter comparer;
  if (await output.exists()) {
    final content = json.decode(await output.readAsString());
    final oldData = (content as Map).cast<String, double>();
    comparer = ComparingEmitter(oldData);
  } else {
    comparer = ComparingEmitter();
  }

  final emitter = MultiEmitter([tracker, comparer]);
  final benchmarks = allBenchmarks(emitter);

  for (final benchmark in benchmarks) {
    await benchmark.report();
  }

  output.writeAsStringSync(json.encode(tracker.timings));

  // Make sure the process exits. Otherwise, unclosed resources from the
  // benchmarks will keep the process alive.
  exit(0);
}
