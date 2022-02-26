import 'dart:async';

import 'package:benchmark_harness/benchmark_harness.dart' show ScoreEmitter;
import 'package:intl/intl.dart';

import 'src/moor/key_value_insert.dart';
import 'src/sqlite/bind_string.dart';
import 'src/sqlparser/parse_drift_file.dart';
import 'src/sqlparser/tokenizer.dart';

export 'package:benchmark_harness/benchmark_harness.dart' show ScoreEmitter;

part 'benchmark_base.dart';

List<Reportable> allBenchmarks(ScoreEmitter emitter) {
  return [
    // low-level sqlite native interop
    SelectStringBenchmark(emitter),
    // high-level moor apis
    KeyValueInsertBatch(emitter),
    KeyValueInsertSerial(emitter),
    // sql parser
    ParseDriftFile(emitter),
    TokenizerBenchmark(emitter),
  ];
}

class TrackingEmitter implements ScoreEmitter {
  /// The average time it took to run each benchmark, in microseconds.
  final Map<String, double> timings = {};

  @override
  void emit(String testName, double value) {
    timings[testName] = value;
  }
}

class ComparingEmitter implements ScoreEmitter {
  final Map<String, double> oldTimings;

  static final _percent = NumberFormat('##.##%');

  ComparingEmitter([this.oldTimings = const {}]);

  @override
  void emit(String testName, double value) {
    final content = StringBuffer(testName)
      ..write(': ')
      ..write(value)
      ..write(' us');

    if (oldTimings.containsKey(testName)) {
      final oldTime = oldTimings[testName]!;
      final increasedTime = value - oldTime;

      final relative = increasedTime.abs() / oldTime;

      content.write('; delta: ');
      if (increasedTime < 0) {
        content
          ..write('$increasedTime us, -')
          ..write(_percent.format(relative));
      } else {
        content
          ..write('+$increasedTime us, +')
          ..write(_percent.format(relative));
      }
    }

    print(content);
  }
}

class MultiEmitter implements ScoreEmitter {
  final List<ScoreEmitter> delegates;

  const MultiEmitter(this.delegates);

  @override
  void emit(String testName, double value) {
    for (final delegate in delegates) {
      delegate.emit(testName, value);
    }
  }
}
