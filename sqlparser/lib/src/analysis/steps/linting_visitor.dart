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

  @override
  void visitValuesSelectStatement(ValuesSelectStatement e, void arg) {
    final expectedColumns = e.resolvedColumns.length;

    for (final tuple in e.values) {
      final elementsInTuple = tuple.expressions.length;

      if (elementsInTuple != expectedColumns) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.valuesSelectCountMismatch,
          relevantNode: tuple,
          message: 'The surrounding VALUES clause has $expectedColumns '
              'columns, but this tuple only has $elementsInTuple',
        ));
      }
    }

    visitChildren(e, arg);
  }
}
