part of '../analysis.dart';

/// Resolves the type of columns in a select statement and the type of
/// expressions appearing in a select statement.
class TypeResolvingVisitor extends RecursiveVisitor<void> {
  final AnalysisContext context;
  TypeResolver get types => context.types;

  TypeResolvingVisitor(this.context);

  @override
  void visitChildren(AstNode e) {
    // called for every ast node, so we implement this here
    if (e is Expression) {
      types.resolveExpression(e);
    } else if (e is SelectStatement) {
      e.resolvedColumns.forEach(types.resolveColumn);
    }

    super.visitChildren(e);
  }
}
