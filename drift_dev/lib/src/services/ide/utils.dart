import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';

extension CurrentResults on FoundFile {
  ParsedDriftFile? get parsedMoorOrNull {
    final result = currentResult;
    if (result is ParsedDriftFile && isParsed) {
      return result;
    }
    return null;
  }
}
