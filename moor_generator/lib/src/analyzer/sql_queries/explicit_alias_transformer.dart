import 'package:sqlparser/sqlparser.dart';

class ExplicitAliasTransformer extends Transformer<bool> {
  int _aliasCounter = 0;
  final Map<Expression, String> _renamed = {};

  AstNode rewrite(AstNode node) {
    node = transform(node, true)!;
    return _PatchReferences(this).transform(node, null)!;
  }

  String? newNameFor(Column column) {
    while (column is CompoundSelectColumn) {
      // In compound select statement, the first column determines the overall
      // name
      column = column.columns.first;
    }

    if (column is ExpressionColumn) {
      return _renamed[column.expression];
    }
  }

  @override
  AstNode? visitCommonTableExpression(CommonTableExpression e, bool arg) {
    // No need to add explicit column names when they're defined in the CTE
    // definition.
    e.as = transformChild(e.as, e, arg && e.columnNames == null);
    return e;
  }

  @override
  AstNode? visitCompoundSelectStatement(CompoundSelectStatement e, bool arg) {
    // For compound select statements, the column names are only determined by
    // the base select statement. So, let's not transform the names in the other
    // select statements.
    e.withClause = transformNullableChild(e.withClause, e, arg);
    e.base = transformChild(e.base, e, arg);
    e.additional = transformChildren(e.additional, e, false);
    return e;
  }

  @override
  AstNode? visitExpressionResultColumn(ExpressionResultColumn e, bool arg) {
    final expr = e.expression;
    if (expr is! Reference && e.as == null && arg) {
      // Automatically add an alias to column names
      final name = '_c${_aliasCounter++}';
      _renamed[expr] = name;
      return super.visitExpressionResultColumn(
        ExpressionResultColumn(expression: expr, as: name),
        arg,
      );
    } else {
      return super.visitExpressionResultColumn(e, arg);
    }
  }
}

class _PatchReferences extends Transformer<void> {
  final ExplicitAliasTransformer _transformer;

  _PatchReferences(this._transformer);

  @override
  AstNode? visitReference(Reference e, void arg) {
    final resolved = e.resolvedColumn;
    if (resolved != null) {
      final name = _transformer.newNameFor(resolved);
      if (name != null) {
        return Reference(columnName: name, entityName: e.entityName);
      }
    }

    return e;
  }
}
