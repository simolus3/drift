part of '../analysis.dart';

class ReferenceResolver extends RecursiveVisitor<void> {
  final AnalysisContext context;

  ReferenceResolver(this.context);

  @override
  void visitReference(Reference e) {
    final scope = e.scope;

    if (e.tableName != null) {
      // first find the referenced table, then use the column on that table.
      final tableResolver =
          scope.resolve<ResolvesToResultSet>(e.tableName, orElse: () {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          message: 'Unknown table: ${e.tableName}',
          relevantNode: e,
        ));
      });
      final resultSet = tableResolver.resultSet;

      if (resultSet == null) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          relevantNode: e,
        ));
      } else {
        final column = resultSet.findColumn(e.columnName);
        if (column == null) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.referencedUnknownColumn,
            relevantNode: e,
          ));
        } else {
          e.resolved = column;
        }
      }
    } else {
      // find any column with the referenced name.
      // todo special case for USING (...) in joins?
      final tables = scope.allOf<ResolvesToResultSet>();
      final columns = tables
          .map((t) => t.resultSet.findColumn(e.columnName))
          .where((c) => c != null)
          .toSet();

      if (columns.isEmpty) {
        context.reportError(AnalysisError(
            type: AnalysisErrorType.referencedUnknownColumn, relevantNode: e));
      } else {
        if (columns.length > 1) {
          context.reportError(AnalysisError(
              type: AnalysisErrorType.ambiguousReference, relevantNode: e));
        }

        e.resolved = columns.first;
      }
    }

    visitChildren(e);
  }
}
