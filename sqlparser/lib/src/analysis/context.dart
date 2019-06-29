part of 'analysis.dart';

class AnalysisContext {
  final List<AnalysisError> errors = [];
  final AstNode root;
  final String sql;
  final TypeResolver types = TypeResolver();

  AnalysisContext(this.root, this.sql);

  void reportError(AnalysisError error) {
    errors.add(error);
  }

  ResolveResult typeOf(Typeable t) => types.resolveOrInfer(t);
}
