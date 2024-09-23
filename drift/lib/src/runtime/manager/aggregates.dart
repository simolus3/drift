part of 'manager.dart';

/// Extension type for an [Expression] that that should be used in an annotation
///
/// The purpose of this extension type is to cooerce an expression which references
/// multiple rows on another table into an annotation.
extension type AggregateBuilder<T extends Object>(Expression<T> expression) {
  /// Returns how often this expression is non-null in the current group.
  ///
  /// For `COUNT(*)`, which would count all rows, see [countAll].
  ///
  /// If [distinct] is set (defaults to false), duplicate values will not be
  /// counted twice.
  /// {@macro drift_aggregate_filter}
  Expression<int> count({bool distinct = false, Expression<bool>? filter}) =>
      expression.count(distinct: distinct, filter: filter);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<T> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<T> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);

  /// Returns the concatenation of all non-null values in the current group,
  /// joined by the [separator].
  ///
  /// The order of the concatenated elements is arbitrary. If no non-null values
  /// exist in the group, `NULL` is returned.
  ///
  /// If [distinct] is set to `true` (it defaults to `false`), duplicate
  /// elements are not added to the combined string twice.
  ///
  /// {@macro drift_aggregate_filter}
  ///
  /// See also:
  ///  - the sqlite documentation: https://www.sqlite.org/lang_aggfunc.html#groupconcat
  ///  - the conceptually similar [Iterable.join]
  Expression<String> groupConcat({
    String separator = ',',
    bool distinct = false,
    Expression<bool>? filter,
  }) =>
      expression.groupConcat(
          separator: separator, distinct: distinct, filter: filter);
}

/// Provides aggregate functions that are available for numeric expressions.
extension ArithmeticAggregateBuilder<DT extends num> on AggregateBuilder<DT> {
  /// Return the average of all non-null values in this group.
  ///
  /// {@macro drift_aggregate_filter}
  Expression<double> avg({Expression<bool>? filter}) =>
      expression.avg(filter: filter);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values are null, evaluates to null as well. If an overflow occurs
  /// during calculation, sqlite will terminate the query with an "integer
  /// overflow" exception.
  ///
  /// See also [total], which behaves similarly but returns a floating point
  /// value and doesn't throw an overflow exception.
  /// {@macro drift_aggregate_filter}
  Expression<DT> sum({Expression<bool>? filter}) =>
      expression.sum(filter: filter);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values in the group are null, [total] returns `0.0`. This function
  /// uses floating-point values internally.
  /// {@macro drift_aggregate_filter}
  Expression<double> total({Expression<bool>? filter}) =>
      expression.total(filter: filter);
}

/// Provides aggregate functions that are available for BigInt expressions.
extension BigIntAggregateBuilder on AggregateBuilder<BigInt> {
  /// Return the average of all non-null values in this group.
  ///
  /// {@macro drift_aggregate_filter}
  Expression<double> avg({Expression<bool>? filter}) =>
      expression.avg(filter: filter);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<BigInt> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<BigInt> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values are null, evaluates to null as well. If an overflow occurs
  /// during calculation, sqlite will terminate the query with an "integer
  /// overflow" exception.
  ///
  /// See also [total], which behaves similarly but returns a floating point
  /// value and doesn't throw an overflow exception.
  /// {@macro drift_aggregate_filter}
  Expression<BigInt> sum({Expression<bool>? filter}) =>
      expression.sum(filter: filter);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values in the group are null, [total] returns `0.0`. This function
  /// uses floating-point values internally.
  /// {@macro drift_aggregate_filter}
  Expression<double> total({Expression<bool>? filter}) =>
      expression.total(filter: filter);
}

/// Provides aggregate functions that are available on date time expressions.
extension DateTimeAggregateBuilder on AggregateBuilder<DateTime> {
  /// Return the average of all non-null values in this group.
  /// {@macro drift_aggregate_filter}
  Expression<DateTime> avg({Expression<bool>? filter}) =>
      expression.avg(filter: filter);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DateTime> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DateTime> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);
}
