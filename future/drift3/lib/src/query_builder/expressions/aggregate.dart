import 'package:collection/collection.dart';

import '../clauses/order_by.dart';
import '../compiler.dart';
import 'datetime.dart';
import 'expression.dart';
import 'variables.dart';

/// Returns the amount of rows in the current group matching the optional
/// [filter].
///
/// {@template drift_aggregate_filter}
/// To only consider rows matching a predicate, you can set the optional
/// [filter]. Note that [filter] is only available from sqlite 3.30, released on
/// 2019-10-04. Most devices will use an older sqlite version when not using
/// `sqlite3_flutter_libs`.
/// {@endtemplate}
///
/// This is equivalent to the `COUNT(*) FILTER (WHERE filter)` sql function. The
/// filter will be omitted if null.
Expression<int> countAll({Expression<bool>? filter}) {
  return AggregateFunctionExpression('COUNT', const [
    StarFunctionParameter(),
  ], filter: filter);
}

/// Provides aggregate functions that are available for each expression.
extension BaseAggregate<DT extends Object> on Expression<DT> {
  /// Returns how often this expression is non-null in the current group.
  ///
  /// For `COUNT(*)`, which would count all rows, see [countAll].
  ///
  /// If [distinct] is set (defaults to false), duplicate values will not be
  /// counted twice.
  /// {@macro drift_aggregate_filter}
  Expression<int> count({bool distinct = false, Expression<bool>? filter}) {
    return AggregateFunctionExpression(
      'COUNT',
      [this],
      filter: filter,
      distinct: distinct,
    );
  }

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT> max({Expression<bool>? filter}) =>
      AggregateFunctionExpression('MAX', [this], filter: filter);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT> min({Expression<bool>? filter}) =>
      AggregateFunctionExpression('MIN', [this], filter: filter);

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
  /// {@template drift_aggregate_order_by}
  /// To control the order of the concatenated elements, you can use [orderBy].
  /// Note that [orderBy] is only available from sqlite 3.44, released on
  /// 2023-11-01. Most devices will use an older sqlite version.
  /// {@endtemplate}
  ///
  /// See also:
  ///  - the sqlite documentation: https://www.sqlite.org/lang_aggfunc.html#groupconcat
  ///  - the conceptually similar [Iterable.join]
  Expression<String> groupConcat({
    String separator = ',',
    bool distinct = false,
    Expression<bool>? filter,
    OrderBy? orderBy,
  }) {
    const sqliteDefaultSeparator = ',';

    // Distinct aggregates can only have one argument
    if (distinct && separator != sqliteDefaultSeparator) {
      throw ArgumentError(
        'Cannot use groupConcat with distinct: true and a custom separator',
      );
    }

    return AggregateFunctionExpression(
      'GROUP_CONCAT',
      [
        this,
        if (separator != sqliteDefaultSeparator) Variable.withString(separator),
      ],
      distinct: distinct,
      filter: filter,
      orderBy: orderBy,
    );
  }
}

/// Provides aggregate functions that are available for numeric expressions.
extension ArithmeticAggregates<DT extends num> on Expression<DT> {
  /// Return the average of all non-null values in this group.
  ///
  /// {@macro drift_aggregate_filter}
  Expression<double> avg({Expression<bool>? filter}) =>
      AggregateFunctionExpression('AVG', [this], filter: filter);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT> max({Expression<bool>? filter}) =>
      AggregateFunctionExpression('MAX', [this], filter: filter);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT> min({Expression<bool>? filter}) =>
      AggregateFunctionExpression('MIN', [this], filter: filter);

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
      AggregateFunctionExpression('SUM', [this], filter: filter);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values in the group are null, [total] returns `0.0`. This function
  /// uses floating-point values internally.
  /// {@macro drift_aggregate_filter}
  Expression<double> total({Expression<bool>? filter}) =>
      AggregateFunctionExpression('TOTAL', [this], filter: filter);
}

/// Provides aggregate functions that are available for BigInt expressions.
extension BigIntAggregates on Expression<BigInt> {
  /// Return the average of all non-null values in this group.
  ///
  /// {@macro drift_aggregate_filter}
  Expression<double> avg({Expression<bool>? filter}) =>
      dartCast<int>().avg(filter: filter);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<BigInt> max({Expression<bool>? filter}) =>
      dartCast<int>().max(filter: filter).dartCast<BigInt>();

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<BigInt> min({Expression<bool>? filter}) =>
      dartCast<int>().min(filter: filter).dartCast<BigInt>();

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
      dartCast<int>().sum(filter: filter).dartCast<BigInt>();

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values in the group are null, [total] returns `0.0`. This function
  /// uses floating-point values internally.
  /// {@macro drift_aggregate_filter}
  Expression<double> total({Expression<bool>? filter}) =>
      dartCast<int>().total(filter: filter);
}

/// Provides aggregate functions that are available on date time expressions.
extension DateTimeAggregate on Expression<DateTime> {
  Expression<DateTime> _byUnixEpoch(
    Expression<int> Function(Expression<int>) transform,
  ) {
    return DateTimeExpressions.fromUnixEpoch(transform(unixepoch));
  }

  /// Return the average of all non-null values in this group.
  /// {@macro drift_aggregate_filter}
  Expression<DateTime> avg({Expression<bool>? filter}) {
    return _byUnixEpoch((e) => e.avg(filter: filter).dartCast());
  }

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DateTime> max({Expression<bool>? filter}) {
    return _byUnixEpoch((e) => e.max(filter: filter).dartCast());
  }

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DateTime> min({Expression<bool>? filter}) {
    return _byUnixEpoch((e) => e.min(filter: filter).dartCast());
  }
}

/// An expression invoking an [aggregate function](https://www.sqlite.org/lang_aggfunc.html).
///
/// Aggregate functions, like `count()` or `sum()` collapse the entire data set
/// (or a partition of it, if `GROUP BY` is used) into a single value.
///
/// Drift exposes direct bindings to most aggregate functions (e.g. via
/// [BaseAggregate.count]). This class is useful when writing custom aggregate
/// function invocations.
final class AggregateFunctionExpression<D extends Object>
    extends Expression<D> {
  /// The name of the aggregate function to invoke.
  final String functionName;

  /// Whether only distinct rows should be passed to the function.
  final bool distinct;

  /// The arguments to pass to the function.
  final List<FunctionParameter> arguments;

  /// The order in which rows of the current group should be passed to the
  /// aggregate function.
  final OrderBy? orderBy;

  /// An optional filter clause only passing rows matching this condition into
  /// the function.
  final Expression<bool>? filter;

  /// Creates an aggregate function expression from the syntactic components.
  AggregateFunctionExpression(
    this.functionName,
    this.arguments, {
    this.filter,
    this.distinct = false,
    this.orderBy,
  });

  @override
  final Precedence precedence = Precedence.primary;

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addAggregateFunctionExpression(this);
  }

  @override
  int get hashCode {
    return Object.hash(
      functionName,
      distinct,
      const ListEquality<Object?>().hash(arguments),
      orderBy,
      filter,
    );
  }

  @override
  bool operator ==(Object other) {
    if (!identical(this, other) && other is! AggregateFunctionExpression<D>) {
      return false;
    }

    final typedOther = other as AggregateFunctionExpression<D>;
    return typedOther.functionName == functionName &&
        typedOther.distinct == distinct &&
        const ListEquality<Object?>().equals(typedOther.arguments, arguments) &&
        typedOther.orderBy == orderBy &&
        typedOther.filter == filter;
  }
}
