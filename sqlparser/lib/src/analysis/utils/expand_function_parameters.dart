part of '../analysis.dart';

/// Extension to expand parameters defined in a sql invocation, which is either
/// a [FunctionExpression] or an [AggregateExpression].
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
      return scope.availableColumns.whereType<TableColumn>().toList();
    }

    throw ArgumentError('Unknown parameters: $sqlParameters');
  }
}
