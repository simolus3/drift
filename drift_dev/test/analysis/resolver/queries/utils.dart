import 'package:drift_dev/src/analysis/results/results.dart';

import '../../test_utils.dart';

Future<SqlQuery> analyzeSingleQueryInDriftFile(String driftFile) async {
  final file = await TestBackend.analyzeSingle(driftFile);
  return file.fileAnalysis!.resolvedQueries.values.single;
}

Future<SqlQuery> analyzeQuery(String sql) async {
  return analyzeSingleQueryInDriftFile('a: $sql');
}
