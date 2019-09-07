part of '../analysis.dart';

/// Resolves any open [Reference] it finds in the AST.
class ReferenceResolver extends RecursiveVisitor<void> {
  final AnalysisContext context;

  ReferenceResolver(this.context);

  @override
  void visitReference(Reference e) {
    if (e.resolved != null) {
      return super.visitReference(e);
    }

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
      final columns =
          scope.availableColumns.where((c) => c?.name == e.columnName).toSet();

      if (columns.isEmpty) {
        context.reportError(AnalysisError(
            type: AnalysisErrorType.referencedUnknownColumn, relevantNode: e));
      } else {
        if (columns.length > 1) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.ambiguousReference,
            relevantNode: e,
            message: 'Could refer to any in ${columns.join(', ')}',
          ));
        }

        e.resolved = columns.first;
      }
    }

    visitChildren(e);
  }

  @override
  void visitAggregateExpression(AggregateExpression e) {
    if (e.windowName != null && e.resolved == null) {
      final resolved = e.scope.resolve<NamedWindowDeclaration>(e.windowName);
      e.resolved = resolved;
    }

    visitChildren(e);
  }
}
