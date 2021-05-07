part of '../query_builder.dart';

/// Returns the amount of rows in the current group matching the optional
/// [filter].
///
/// To only count rows matching a predicate, you can set the optional [filter].
/// Note that [filter] is only available from sqlite 3.30, released on
/// 2019-10-04. Most devices will use an older sqlite version.
///
/// This is equivalent to the `COUNT(*) FILTER (WHERE filter)` sql function. The
/// filter will be omitted if null.
Expression<int> countAll({Expression<bool?>? filter}) {
  return _AggregateExpression('COUNT', const _StarFunctionParameter(),
      filter: filter);
}

/// Provides aggregate functions that are available for each expression.
extension BaseAggregate<DT> on Expression<DT> {
  /// Returns how often this expression is non-null in the current group.
  ///
  /// For `COUNT(*)`, which would count all rows, see [countAll].
  ///
  /// If [distinct] is set (defaults to false), duplicate values will not be
  /// counted twice. An optional [filter] can be used to only include values
  /// matching the filter. Note that [filter] is only available from sqlite
  /// 3.30 and most devices will use an older sqlite version.
  Expression<int> count({bool? distinct, Expression<bool?>? filter}) {
    return _AggregateExpression('COUNT', this,
        filter: filter, distinct: distinct);
  }

  /// Returns the concatenation of all non-null values in the current group,
  /// joined by the [separator].
  ///
  /// The order of the concatenated elements is arbitrary.
  ///
  /// See also:
  ///  - the sqlite documentation: https://www.sqlite.org/lang_aggfunc.html#groupconcat
  ///  - the conceptually similar [Iterable.join]
  Expression<String> groupConcat({String separator = ','}) {
    const sqliteDefaultSeparator = ',';
    if (separator == sqliteDefaultSeparator) {
      return _AggregateExpression('GROUP_CONCAT', this);
    } else {
      return FunctionCallExpression(
          'GROUP_CONCAT', [this, Variable.withString(separator)]);
    }
  }
}

/// Provides aggregate functions that are available for numeric expressions.
extension ArithmeticAggregates<DT extends num> on Expression<DT?> {
  /// Return the average of all non-null values in this group.
  Expression<double?> avg() => _AggregateExpression('AVG', this);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  Expression<DT?> max() => _AggregateExpression('MAX', this);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  Expression<DT?> min() => _AggregateExpression('MIN', this);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values are null, evaluates to null as well. If an overflow occurs
  /// during calculation, sqlite will terminate the query with an "integer
  /// overflow" exception.
  ///
  /// See also [total], which behaves similarly but returns a floating point
  /// value and doesn't throw an overflow exception.
  Expression<DT?> sum() => _AggregateExpression('SUM', this);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values in the group are null, [total] returns `0.0`. This function
  /// uses floating-point values internally.
  Expression<double?> total() => _AggregateExpression('TOTAL', this);
}

/// Provides aggregate functions that are available on date time expressions.
extension DateTimeAggregate on Expression<DateTime?> {
  /// Return the average of all non-null values in this group.
  Expression<DateTime> avg() => secondsSinceEpoch.avg().roundToInt().dartCast();

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  Expression<DateTime> max() => _AggregateExpression('MAX', this);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  Expression<DateTime> min() => _AggregateExpression('MIN', this);
}

class _AggregateExpression<D> extends Expression<D> {
  final String functionName;
  final bool distinct;
  final FunctionParameter parameter;

  final Where? filter;

  _AggregateExpression(this.functionName, this.parameter,
      {Expression<bool?>? filter, bool? distinct})
      : filter = filter != null ? Where(filter) : null,
        distinct = distinct ?? false;

  @override
  final Precedence precedence = Precedence.primary;

  @override
  void writeInto(GenerationContext context) {
    context.buffer..write(functionName)..write('(');

    if (distinct) {
      context.buffer.write('DISTINCT ');
    }

    parameter.writeInto(context);
    context.buffer.write(')');

    if (filter != null) {
      context.buffer.write(' FILTER (');
      filter!.writeInto(context);
      context.buffer.write(')');
    }
  }

  @override
  int get hashCode {
    return $mrjf($mrjc(functionName.hashCode,
        $mrjc(distinct.hashCode, $mrjc(parameter.hashCode, filter.hashCode))));
  }

  @override
  bool operator ==(dynamic other) {
    if (!identical(this, other) && other.runtimeType != runtimeType) {
      return false;
    }

    // ignore: test_types_in_equals
    final typedOther = other as _AggregateExpression;
    return typedOther.functionName == functionName &&
        typedOther.distinct == distinct &&
        typedOther.parameter == parameter &&
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
