part of 'analysis.dart';

class AnalysisContext {
  final List<AnalysisError> errors = [];
  final AstNode root;

  AnalysisContext(this.root);

  void reportError(AnalysisError error) {
    errors.add(error);
  }
}
