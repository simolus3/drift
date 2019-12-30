part of 'benchmarks.dart';

// Some parts copied from https://github.com/dart-lang/benchmark_harness
// Copyright 2011 Google Inc. All Rights Reserved.

// Forked to create the async counterpart and the common Reportable class

abstract class Reportable {
  FutureOr<void> report();
}

abstract class BenchmarkBase implements Reportable {
  final String name;
  final ScoreEmitter emitter;

  const BenchmarkBase(this.name, this.emitter);

  void run();

  void warmup() {
    run();
  }

  void exercise() {
    for (var i = 0; i < 10; i++) {
      run();
    }
  }

  void setup() {}

  void teardown() {}

  static double measureFor(Function f, int minimumMillis) {
    final minimumMicros = minimumMillis * 1000;
    var iter = 0;
    final watch = Stopwatch();
    watch.start();
    var elapsed = 0;
    while (elapsed < minimumMicros) {
      f();
      elapsed = watch.elapsedMicroseconds;
      iter++;
    }
    return elapsed / iter;
  }

  double measure() {
    setup();
    // Warmup for at least 100ms. Discard result.
    measureFor(warmup, 100);
    // Run the benchmark for at least 2000ms.
    final result = measureFor(exercise, 2000);
    teardown();
    return result;
  }

  @override
  void report() {
    emitter.emit(name, measure());
  }
}

abstract class AsyncBenchmarkBase implements Reportable {
  final String name;
  final ScoreEmitter emitter;

  const AsyncBenchmarkBase(this.name, this.emitter);

  Future<void> run();

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

  @override
  Future<void> report() async {
    emitter.emit(name, await measure());
  }
}
