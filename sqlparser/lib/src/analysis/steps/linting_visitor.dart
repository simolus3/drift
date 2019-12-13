part of '../analysis.dart';

/// Visitor that runs after all other steps ran and reports more complex lints
/// on an sql statement.
class LintingVisitor extends RecursiveVisitor<void> {
  final EngineOptions options;
  final AnalysisContext context;

  LintingVisitor(this.options, this.context);

  @override
  void visitAggregateExpression(Invocation e) => _visitInvocation(e);

  @override
  void visitFunction(Invocation e) => _visitInvocation(e);

  void _visitInvocation(Invocation e) {
    final lowercaseCall = e.name.toLowerCase();
    if (options.addedFunctions.containsKey(lowercaseCall)) {
      options.addedFunctions[lowercaseCall].reportErrors(e, context);
    }

    visitChildren(e);
  }
}
