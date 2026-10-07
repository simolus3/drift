import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/native.dart';
import 'package:drift_sqlite/src/dialect/dialect.dart';

// Run with dart run benchmark_harness:bench --flavor jit --target benchmark/native_queries.dart
void main() {
  QueriesBenchmark(10_000, false).report();
  QueriesBenchmark(10_000, true).report();
}

class QueriesBenchmark extends AsyncBenchmarkBase {
  final int dataSize;
  final bool useBackgroundIsolates;

  QueriesBenchmark(this.dataSize, this.useBackgroundIsolates)
    : super(
        'Running queries ($dataSize, background isolates: $useBackgroundIsolates',
      );

  late Directory _tempDir;
  late OpenedDriftConnection _connection;

  @override
  Future<void> setup() async {
    _tempDir = await Directory.systemTemp.createTemp('drift_bench');
    final pool = sqliteConnectionPool(
      file: File('${_tempDir.path}/app.db'),
      useBackgroundIsolates: useBackgroundIsolates,
    );
    _connection = await pool.open(const SqliteDialect.withOptions());
  }

  @override
  Future<void> run() async {
    await _connection.session.execute(
      StatementInfo('SELECT 1', isReadOnly: true, needsResultSet: true),
    );
  }

  @override
  Future<void> teardown() async {
    await _connection.session.close();
    await _tempDir.delete(recursive: true);
  }
}
