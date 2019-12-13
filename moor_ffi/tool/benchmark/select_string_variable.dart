import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:moor_ffi/database.dart';

class SelectStringBenchmark extends BenchmarkBase {
  SelectStringBenchmark() : super('SELECT a string variable');

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
  void teardown() {
    statement.close();
    database.close();
  }
}
