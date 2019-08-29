part of '../analysis.dart';

/// Resolves types for all nodes in the AST which can have a type. This includes
/// expressions, variables and so on. For select statements, we also try to
/// figure out what types they return.
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

  @override
  void visitInsertStatement(InsertStatement e) {
    // resolve target columns - this is easy, as we should have the table
    // structure available.
    e.targetColumns.forEach(types.resolveExpression);

    // if the insert statement has a VALUES source, we can now infer the type
    // for those expressions by comparing with the target column.
    if (e.source is ValuesSource) {
      final targetTypes = e.resolvedTargetColumns.map(context.typeOf).toList();
      final source = e.source as ValuesSource;

      for (var tuple in source.values) {
        final expressions = tuple.expressions;
        for (var i = 0; i < min(expressions.length, targetTypes.length); i++) {
          if (i < targetTypes.length) {
            context.types.markResult(expressions[i], targetTypes[i]);
          }
        }
      }
    }

    visitChildren(e);
  }
}
