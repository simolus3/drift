part of '../query_builder.dart';

/// Defines extension functions to express comparisons in sql
extension ComparableExpr<DT extends Comparable<dynamic>> on Expression<DT> {
  /// Returns an expression that is true if this expression is strictly bigger
  /// than the other expression.
  Expression<bool> isBiggerThan(Expression<DT> other) {
    return _Comparison(this, _ComparisonOperator.more, other);
  }

  /// Returns an expression that is true if this expression is strictly bigger
  /// than the other value.
  Expression<bool> isBiggerThanValue(DT other) {
    return isBiggerThan(variable(other));
  }

  /// Returns an expression that is true if this expression is bigger than or
  /// equal to he other expression.
  Expression<bool> isBiggerOrEqual(Expression<DT> other) {
    return _Comparison(this, _ComparisonOperator.moreOrEqual, other);
  }

  /// Returns an expression that is true if this expression is bigger than or
  /// equal to he other value.
  Expression<bool> isBiggerOrEqualValue(DT other) {
    return isBiggerOrEqual(variable(other));
  }

  /// Returns an expression that is true if this expression is strictly smaller
  /// than the other expression.
  Expression<bool> isSmallerThan(Expression<DT> other) {
    return _Comparison(this, _ComparisonOperator.less, other);
  }

  /// Returns an expression that is true if this expression is strictly smaller
  /// than the other value.
  Expression<bool> isSmallerThanValue(DT other) =>
      isSmallerThan(variable(other));

  /// Returns an expression that is true if this expression is smaller than or
  /// equal to he other expression.
  Expression<bool> isSmallerOrEqual(Expression<DT> other) {
    return _Comparison(this, _ComparisonOperator.lessOrEqual, other);
  }

  /// Returns an expression that is true if this expression is smaller than or
  /// equal to he other value.
  Expression<bool> isSmallerOrEqualValue(DT other) {
    return isSmallerOrEqual(variable(other));
  }

  /// Returns an expression evaluating to true if this expression is between
  /// [lower] and [higher] (both inclusive).
  ///
  /// If [not] is set, the expression will be negated. To compare this
  /// expression against two values, see
  Expression<bool> isBetween(Expression<DT> lower, Expression<DT> higher,
      {bool not = false}) {
    return _BetweenExpression(
        target: this, lower: lower, higher: higher, not: not);
  }

  /// Returns an expression evaluating to true if this expression is between
  /// [lower] and [higher] (both inclusive).
  ///
  /// If [not] is set, the expression will be negated.
  Expression<bool> isBetweenValues(DT lower, DT higher, {bool not = false}) {
    return _BetweenExpression(
      target: this,
      lower: variable(lower),
      higher: variable(higher),
      not: not,
    );
  }
}

class _BetweenExpression extends Expression<bool> {
  final Expression target;

  // https://www.sqlite.org/lang_expr.html#between
  @override
  final Precedence precedence = Precedence.comparisonEq;

  /// Whether to negate this between expression
  final bool not;

  final Expression lower;
  final Expression higher;

  _BetweenExpression(
      {required this.target,
      required this.lower,
      required this.higher,
      this.not = false});

  @override
  void writeInto(GenerationContext context) {
    var target = this.target;
    var lower = this.lower;
    var higher = this.higher;

    // We don't want to compare datetime values lexicographically, so we convert
    // them to a comparable unit
    if (context.typeMapping.storeDateTimesAsText) {
      if (target is Expression<DateTime>) target = target.julianday;
      if (lower is Expression<DateTime>) lower = lower.julianday;
      if (higher is Expression<DateTime>) higher = higher.julianday;
    }

    writeInner(context, target);

    if (not) context.buffer.write(' NOT');
    context.buffer.write(' BETWEEN ');

    writeInner(context, lower);
    context.buffer.write(' AND ');
    writeInner(context, higher);
  }

  @override
  int get hashCode => Object.hash(target, lower, higher, not);

  @override
  bool operator ==(Object other) {
    return other is _BetweenExpression &&
        other.target == target &&
        other.not == not &&
        other.lower == lower &&
        other.higher == higher;
  }
}
