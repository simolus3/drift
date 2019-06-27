part of 'analysis.dart';

class AnalysisContext {
  final List<AnalysisError> errors = [];
  final AstNode root;
  final String sql;

  AnalysisContext(this.root, this.sql);

  void reportError(AnalysisError error) {
    errors.add(error);
  }
}
