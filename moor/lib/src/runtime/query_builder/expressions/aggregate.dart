part of '../query_builder.dart';

// todo: We should have a detailed article on group-by clauses and aggregate
// expressions on the website

/// Returns the amount of rows in the current group matching the optional
/// [filter].
///
/// To only count instances of a particular
///
/// This is equivalent to the `COUNT(*) FILTER (WHERE filter)` sql function. The
/// filter will be omitted if null.
Expression<int, IntType> countAll({Expression<bool, BoolType> filter}) {
  return _AggregateExpression('COUNT', const _StarFunctionParameter(),
      filter: filter);
}

/// Provides aggregate functions that are available for each expression.
extension BaseAggregate<DT, ST extends SqlType<DT>> on Expression<DT, ST> {
  /// Returns how often this expression is non-null in the current group.
  ///
  /// For `COUNT(*)`, which would count all rows, see [countAll].
  ///
  /// If [distinct] is set (defaults to false), duplicate values will not be
  /// counted twice. An optional [filter] can be used to only include values
  /// matching the filter.
  Expression<int, IntType> count(
      {bool distinct, Expression<bool, BoolType> filter}) {
    return _AggregateExpression('COUNT', this,
        filter: filter, distinct: distinct);
  }
}

/// Provides aggregate functions that are available for numeric expressions.
extension ArithmeticAggregates<DT, ST extends FullArithmetic<DT>>
    on Expression<DT, ST> {
  /// Return the average of all non-null values in this group.
  Expression<double, RealType> avg() => _AggregateExpression('AVG', this);

  /// Return the maximum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  Expression<DT, ST> max() => _AggregateExpression('MAX', this);

  /// Return the minimum of all non-null values in this group.
  ///
  /// If there are no non-null values in the group, returns null.
  Expression<DT, ST> min() => _AggregateExpression('MIN', this);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values are null, evaluates to null as well. If an overflow occurs
  /// during calculation, sqlite will terminate the query with an "integer
  /// overflow" exception.
  ///
  /// See also [total], which behaves similarly but returns a floating point
  /// value and doesn't throw an overflow exception.
  Expression<DT, ST> sum() => _AggregateExpression('SUM', this);

  /// Calculate the sum of all non-null values in the group.
  ///
  /// If all values in the group are null, [total] returns `0.0`. This function
  /// uses floating-point values internally.
  Expression<double, RealType> total() => _AggregateExpression('TOTAL', this);
}

class _AggregateExpression<D, S extends SqlType<D>> extends Expression<D, S> {
  final String functionName;
  final bool distinct;
  final FunctionParameter parameter;

  final Where /*?*/ filter;

  _AggregateExpression(this.functionName, this.parameter,
      {Expression<bool, BoolType> filter, bool distinct})
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
      filter.writeInto(context);
      context.buffer.write(')');
    }
  }
}

class _StarFunctionParameter implements FunctionParameter {
  const _StarFunctionParameter();

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('*');
  }
}
