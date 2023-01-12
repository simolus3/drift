part of '../query_builder.dart';

/// Expression that is true if the inner expression resolves to a null value.
@Deprecated('Use isNull on the Expression class')
Expression<bool> isNull(Expression inner) => inner.isNull();

/// Expression that is true if the inner expression resolves to a non-null
/// value.
@Deprecated('Use isNotNull on the Expression class')
Expression<bool> isNotNull(Expression inner) => inner.isNotNull();

/// Evaluates to the first expression in [expressions] that's not null, or
/// null if all [expressions] evaluate to null.
Expression<T> coalesce<T extends Object>(List<Expression<T>> expressions) {
  assert(expressions.length >= 2,
      'expressions must be of length >= 2, got ${expressions.length}');

  return FunctionCallExpression<T>('COALESCE', expressions);
}

/// Evaluates to the first expression that's not null, or null if both evaluate
/// to null. See [coalesce] if you need more than 2.
Expression<T> ifNull<T extends Object>(
    Expression<T> first, Expression<T> second) {
  return FunctionCallExpression<T>('IFNULL', [first, second]);
}
