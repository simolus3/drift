part of '../analysis.dart';

/// Extension to expand parameters defined in a sql invocation, which is either
/// a [FunctionExpression] or an [AggregateFunctionInvocation].
extension ExpandParameters on SqlInvocation {
  /// Returns the expanded parameters of a function call.
  ///
  /// When a [StarFunctionParameter] is used, it's expanded to the
  /// [ReferenceScope.availableColumns].
  /// Elements of the result are either an [Expression] or a [Column].
  List<Typeable> expandParameters() {
    final sqlParameters = parameters;

    if (sqlParameters is ExprFunctionParameters) {
      return sqlParameters.parameters;
    } else if (sqlParameters is StarFunctionParameter) {
      // if * is used as a parameter, it refers to all columns in all tables
      // that are available in the current scope.
      final allColumns = scope.availableColumns;

      // When we look at `SELECT SUM(*), foo FROM ...`, the star in `SUM`
      // shouldn't expand to include itself.
      final unrelated = allColumns.where((column) {
        if (column is! ExpressionColumn) return true;

        final expression = column.expression;
        return !expression.selfAndDescendants.contains(this);
      });

      return unrelated.toList();
    }

    throw ArgumentError('Unknown parameters: $sqlParameters');
  }
}
