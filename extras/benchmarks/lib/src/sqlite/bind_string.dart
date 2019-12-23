import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:moor_ffi/database.dart';

class SelectStringBenchmark extends BenchmarkBase {
  SelectStringBenchmark(ScoreEmitter emitter)
      : super('SELECTing a single string variable', emitter: emitter);

  PreparedStatement statement;
  Database database;

  @override
  void setup() {
    database = Database.memory();
    statement = database.prepare('SELECT ?;');
  }

  @override
  void run() {
    statement.select(const ['hello sqlite, can you return this string?']);
  }

  @override
  void exercise() {
    // repeat 1000 instead of 10 times to reduce variance
    for (var i = 0; i < 1000; i++) {
      run();
    }
  }

  @override
  void teardown() {
    statement.close();
    database.close();
  }
}
