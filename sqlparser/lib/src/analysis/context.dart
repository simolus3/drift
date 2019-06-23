part of 'analysis.dart';

class AnalysisContext {
  final List<AnalysisError> errors = [];

  void reportError(AnalysisError error) {
    errors.add(error);
  }
}
