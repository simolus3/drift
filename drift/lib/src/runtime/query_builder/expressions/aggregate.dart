part of '../query_builder.dart';

/// Returns the amount of rows in the current group matching the optional
/// [filter].
///
/// {@template drift_aggregate_filter}
/// To only consider rows matching a predicate, you can set the optional
/// [filter]. Note that [filter] is only available from sqlite 3.30, released on
/// 2019-10-04. Most devices will use an older sqlite version.
/// {@endtemplate}
///
/// This is equivalent to the `COUNT(*) FILTER (WHERE filter)` sql function. The
/// filter will be omitted if null.
Expression<int> countAll({Expression<bool?>? filter}) {
  return _AggregateExpression('COUNT', const [_StarFunctionParameter()],
      filter: filter);
}

/// Provides aggregate functions that are available for each expression.
extension BaseAggregate<DT> on Expression<DT> {
  /// Returns how often this expression is non-null in the current group.
  ///
  /// For `COUNT(*)`, which would count all rows, see [countAll].
  ///
  /// If [distinct] is set (defaults to false), duplicate values will not be
  /// counted twice.
  /// {@macro drift_aggregate_filter}
  Expression<int> count({bool distinct = false, Expression<bool?>? filter}) {
    return _AggregateExpression('COUNT', [this],
        filter: filter, distinct: distinct);
  }

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
  Expression<String?> groupConcat({
    String separator = ',',
    bool distinct = false,
    Expression<bool?>? filter,
  }) {
    const sqliteDefaultSeparator = ',';

    // Distinct aggregates can only have one argument
    if (distinct && separator != sqliteDefaultSeparator) {
      throw ArgumentError(
          'Cannot use groupConcat with distinct: true and a custom separator');
    }

    return _AggregateExpression(
      'GROUP_CONCAT',
      [
        this,
        if (separator != sqliteDefaultSeparator) Variable.withString(separator)
      ],
      distinct: distinct,
      filter: filter,
    );
  }
}

/// Provides aggregate functions that are available for numeric expressions.
extension ArithmeticAggregates<DT extends num> on Expression<DT?> {
  /// Return the average of all non-null values in this group.
  ///
  /// {@macro drift_aggregate_filter}
  Expression<double?> avg({Expression<bool?>? filter}) =>
      _AggregateExpression('AVG', [this], filter: filter);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT?> max({Expression<bool?>? filter}) =>
      _AggregateExpression('MAX', [this], filter: filter);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT?> min({Expression<bool?>? filter}) =>
      _AggregateExpression('MIN', [this], filter: filter);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values are null, evaluates to null as well. If an overflow occurs
  /// during calculation, sqlite will terminate the query with an "integer
  /// overflow" exception.
  ///
  /// See also [total], which behaves similarly but returns a floating point
  /// value and doesn't throw an overflow exception.
  /// {@macro drift_aggregate_filter}
  Expression<DT?> sum({Expression<bool?>? filter}) =>
      _AggregateExpression('SUM', [this], filter: filter);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values in the group are null, [total] returns `0.0`. This function
  /// uses floating-point values internally.
  /// {@macro drift_aggregate_filter}
  Expression<double?> total({Expression<bool?>? filter}) =>
      _AggregateExpression('TOTAL', [this], filter: filter);
}

/// Provides aggregate functions that are available for BigInt expressions.
extension BigIntAggregates<DT extends BigInt> on Expression<DT?> {
  /// Return the average of all non-null values in this group.
  ///
  /// {@macro drift_aggregate_filter}
  Expression<double?> avg({Expression<bool?>? filter}) =>
      dartCast<int>().avg(filter: filter);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT?> max({Expression<bool?>? filter}) =>
      dartCast<int>().max(filter: filter).dartCast<DT?>();

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DT?> min({Expression<bool?>? filter}) =>
      dartCast<int>().min(filter: filter).dartCast<DT?>();

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values are null, evaluates to null as well. If an overflow occurs
  /// during calculation, sqlite will terminate the query with an "integer
  /// overflow" exception.
  ///
  /// See also [total], which behaves similarly but returns a floating point
  /// value and doesn't throw an overflow exception.
  /// {@macro drift_aggregate_filter}
  Expression<DT?> sum({Expression<bool?>? filter}) =>
      dartCast<int>().sum(filter: filter).dartCast<DT?>();

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values in the group are null, [total] returns `0.0`. This function
  /// uses floating-point values internally.
  /// {@macro drift_aggregate_filter}
  Expression<double?> total({Expression<bool?>? filter}) =>
      dartCast<int>().total(filter: filter);
}

/// Provides aggregate functions that are available on date time expressions.
extension DateTimeAggregate on Expression<DateTime?> {
  /// Return the average of all non-null values in this group.
  /// {@macro drift_aggregate_filter}
  Expression<DateTime> avg({Expression<bool?>? filter}) =>
      secondsSinceEpoch.avg(filter: filter).roundToInt().dartCast();

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DateTime> max({Expression<bool?>? filter}) =>
      _AggregateExpression('MAX', [this], filter: filter);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  /// {@macro drift_aggregate_filter}
  Expression<DateTime> min({Expression<bool?>? filter}) =>
      _AggregateExpression('MIN', [this], filter: filter);
}

class _AggregateExpression<D> extends Expression<D> {
  final String functionName;
  final bool distinct;
  final List<FunctionParameter> parameter;

  final Where? filter;

  _AggregateExpression(this.functionName, this.parameter,
      {Expression<bool?>? filter, this.distinct = false})
      : filter = filter != null ? Where(filter) : null;

  @override
  final Precedence precedence = Precedence.primary;

  @override
  void writeInto(GenerationContext context) {
    context.buffer
      ..write(functionName)
      ..write('(');

    if (distinct) {
      context.buffer.write('DISTINCT ');
    }
    _writeCommaSeparated(context, parameter);
    context.buffer.write(')');

    if (filter != null) {
      context.buffer.write(' FILTER (');
      filter!.writeInto(context);
      context.buffer.write(')');
    }
  }

  @override
  int get hashCode {
    return Object.hash(
        functionName, distinct, const ListEquality().hash(parameter), filter);
  }

  @override
  bool operator ==(Object other) {
    if (!identical(this, other) && other.runtimeType != runtimeType) {
      return false;
    }

    // ignore: test_types_in_equals
    final typedOther = other as _AggregateExpression;
    return typedOther.functionName == functionName &&
        typedOther.distinct == distinct &&
        const ListEquality().equals(typedOther.parameter, parameter) &&
        typedOther.filter == filter;
  }
}

class _StarFunctionParameter implements FunctionParameter {
  const _StarFunctionParameter();

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('*');
  }
}
