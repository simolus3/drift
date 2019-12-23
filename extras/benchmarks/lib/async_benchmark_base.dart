part of 'benchmarks.dart';

class AsyncBenchmarkBase {
  final String name;
  final ScoreEmitter emitter;

  const AsyncBenchmarkBase(this.name, this.emitter);

  Future<void> run() async {}

  Future<void> warmup() {
    return run();
  }

  Future<void> exercise() {
    return run();
  }

  Future<void> setup() async {}

  Future<void> teardown() async {}

  static Future<double> measureFor(
      Future Function() f, int minimumMillis) async {
    final minimumMicros = minimumMillis * 1000;
    var iter = 0;
    final watch = Stopwatch();
    watch.start();
    var elapsed = 0;
    while (elapsed < minimumMicros) {
      await f();
      elapsed = watch.elapsedMicroseconds;
      iter++;
    }
    return elapsed / iter;
  }

  Future<double> measure() async {
    await setup();
    try {
      // Warmup for at least 100ms. Discard result.
      await measureFor(warmup, 100);
      // Run the benchmark for at least 2000ms.
      return await measureFor(exercise, 2000);
    } finally {
      await teardown();
    }
  }

  Future<void> report() async {
    emitter.emit(name, await measure());
  }
}
