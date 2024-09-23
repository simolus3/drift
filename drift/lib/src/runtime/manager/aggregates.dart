part of 'manager.dart';

/// Extension type for an [Expression] that that should be used in an annotation
///
/// The purpose of this extension type is to cooerce an expression which references
/// multiple rows on another table into an annotation.
extension type AggregateBuilder<T extends Object>(Expression<T> expression) {
  Expression<int> count({bool distinct = false, Expression<bool>? filter}) =>
      expression.count(distinct: distinct, filter: filter);
  Expression<T> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);
  Expression<T> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);
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
  Expression<double> avg({Expression<bool>? filter}) =>
      expression.avg(filter: filter);
  Expression<DT> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);
  Expression<DT> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);
  Expression<DT> sum({Expression<bool>? filter}) =>
      expression.sum(filter: filter);
  Expression<double> total({Expression<bool>? filter}) =>
      expression.total(filter: filter);
}

/// Provides aggregate functions that are available for BigInt expressions.
extension BigIntAggregateBuilder on AggregateBuilder<BigInt> {
  Expression<double> avg({Expression<bool>? filter}) =>
      expression.avg(filter: filter);
  Expression<BigInt> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);
  Expression<BigInt> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);
  Expression<BigInt> sum({Expression<bool>? filter}) =>
      expression.sum(filter: filter);
  Expression<double> total({Expression<bool>? filter}) =>
      expression.total(filter: filter);
}

/// Provides aggregate functions that are available on date time expressions.
extension DateTimeAggregateBuilder on AggregateBuilder<DateTime> {
  Expression<DateTime> avg({Expression<bool>? filter}) =>
      expression.avg(filter: filter);
  Expression<DateTime> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);
  Expression<DateTime> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);
}
