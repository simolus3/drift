import 'package:sqlparser/sqlparser.dart';

/// A transformer adding explicit aliases to columns in a projection.
///
/// In sqlite3, the result name of columns without an alias is undefined. While
/// the names of direct column references (`SELECT foo FROM bar`) is unlikely
/// to change, we shouldn't assume that for more complex columns (`SELECT
/// MAX(id) * 14 FROM bar`). This transformer adds an alias to such columns
/// which avoids undefined behavior that might be different across sqlite3
/// versions.
class ExplicitAliasTransformer extends Transformer<bool> {
  int _aliasCounter = 0;
  final Map<Expression, String> _renamed = {};

  /// Rewrites an SQL [node] to use explicit aliases for columns.
  AstNode rewrite(AstNode node) {
    node = transform(node, true)!;
    return _PatchReferences(this).transform(node, null)!;
  }

  /// Obtain the new name for a [column] after an alias has been added.
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

  @override
  AstNode? visitSubQuery(SubQuery e, bool arg) {
    // Subquery expressions only have a single column, so the inner column
    // doesn't matter. For instance, `SELECT (SELECT 1) AS foo` has no undefined
    // behavior, even though the inner `1` has no alias.
    return e..transformChildren(this, false);
  }
}

class _PatchReferences extends Transformer<void> {
  final ExplicitAliasTransformer _transformer;

  _PatchReferences(this._transformer);

  @override
  AstNode? visitReference(Reference e, void arg) {
    final resolved = e.resolvedColumn?.source;

    if (resolved != null) {
      final name = _transformer.newNameFor(resolved);
      if (name != null) {
        return Reference(columnName: name, entityName: e.entityName);
      }
    }

    return e;
  }
}
