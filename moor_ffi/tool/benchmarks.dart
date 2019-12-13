import 'benchmark/select_string_variable.dart';

void main() {
  final benchmarks = [
    SelectStringBenchmark(),
  ];

  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
