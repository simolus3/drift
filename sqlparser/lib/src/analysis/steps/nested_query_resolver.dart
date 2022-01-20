part of '../analysis.dart';

/// Converts all references in nested queries, that require data from the
/// parent query into variables.
class NestedQueryResolver extends RecursiveVisitor<void, void> {
  final AnalysisContext context;

  NestedQueryResolver(this.context);

  @override
  void visitMoorSpecificNode(MoorSpecificNode e, void arg) {
    if (e is NestedQueryColumn) {
      _transform(context, e);
    } else {
      super.visitMoorSpecificNode(e, arg);
    }
  }
}

void _transform(AnalysisContext context, NestedQueryColumn e) {
  e.select.transformChildren(_NestedQueryTransformer(context), null);

  AstPreparingVisitor.resolveIndexOfVariables(
    e.allDescendants.whereType<Variable>().toList(),
  );
}

class _NestedQueryTransformer extends Transformer<void> {
  final AnalysisContext context;

  _NestedQueryTransformer(this.context);

  @override
  AstNode? visitReference(Reference e, void arg) {
    // if the scope of the nested query cannot resolve the reference, the
    // reference needs to be retrieved from the parent query
    if (e.resultEntity != null && e.resultEntity!.origin.scope != e.scope) {
      final result = e.scope.resolve(e.entityName!);

      if (result == null) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          message: 'Unknown table or view in nested query: ${e.entityName}',
          relevantNode: e,
        ));
      } else {
        return NestedQueryVariable(
          entityName: e.entityName,
          columnName: e.columnName,
        )..setSpan(e.first!, e.last!);
      }
    }

    return super.visitReference(e, arg);
  }

  @override
  AstNode? visitMoorSpecificNode(MoorSpecificNode e, void arg) {
    if (e is NestedQueryColumn) {
      _transform(context, e);

      return e;
    } else {
      return super.visitMoorSpecificNode(e, arg);
    }
  }
}
