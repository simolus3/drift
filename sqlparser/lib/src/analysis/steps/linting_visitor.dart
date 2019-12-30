part of '../analysis.dart';

/// Visitor that runs after all other steps ran and reports more complex lints
/// on an sql statement.
class LintingVisitor extends RecursiveVisitor<void, void> {
  final EngineOptions options;
  final AnalysisContext context;

  LintingVisitor(this.options, this.context);

  @override
  void visitInvocation(SqlInvocation e, void arg) {
    final lowercaseCall = e.name.toLowerCase();
    if (options.addedFunctions.containsKey(lowercaseCall)) {
      options.addedFunctions[lowercaseCall].reportErrors(e, context);
    }

    visitChildren(e, arg);
  }
}
