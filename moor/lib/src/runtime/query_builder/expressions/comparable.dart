part of '../query_builder.dart';

/// Defines extension functions to express comparisons in sql
extension ComparableExpr<DT, ST extends ComparableType<DT>>
    on Expression<DT, ST> {
  /// Returns an expression that is true if this expression is strictly bigger
  /// than the other expression.
  Expression<bool, BoolType> isBiggerThan(Expression<DT, ST> other) {
    return _Comparison(this, _ComparisonOperator.more, other);
  }

  /// Returns an expression that is true if this expression is strictly bigger
  /// than the other value.
  Expression<bool, BoolType> isBiggerThanValue(DT other) =>
      isBiggerThan(Variable(other));

  /// Returns an expression that is true if this expression is bigger than or
  /// equal to he other expression.
  Expression<bool, BoolType> isBiggerOrEqual(Expression<DT, ST> other) {
    return _Comparison(this, _ComparisonOperator.moreOrEqual, other);
  }

  /// Returns an expression that is true if this expression is bigger than or
  /// equal to he other value.
  Expression<bool, BoolType> isBiggerOrEqualValue(DT other) =>
      isBiggerOrEqual(Variable(other));

  /// Returns an expression that is true if this expression is strictly smaller
  /// than the other expression.
  Expression<bool, BoolType> isSmallerThan(Expression<DT, ST> other) {
    return _Comparison(this, _ComparisonOperator.less, other);
  }

  /// Returns an expression that is true if this expression is strictly smaller
  /// than the other value.
  Expression<bool, BoolType> isSmallerThanValue(DT other) =>
      isSmallerThan(Variable(other));

  /// Returns an expression that is true if this expression is smaller than or
  /// equal to he other expression.
  Expression<bool, BoolType> isSmallerOrEqual(Expression<DT, ST> other) {
    return _Comparison(this, _ComparisonOperator.lessOrEqual, other);
  }

  /// Returns an expression that is true if this expression is smaller than or
  /// equal to he other value.
  Expression<bool, BoolType> isSmallerOrEqualValue(DT other) =>
      isSmallerOrEqual(Variable(other));

  /// Returns an expression evaluating to true if this expression is between
  /// [lower] and [higher] (both inclusive).
  ///
  /// If [not] is set, the expression will be negated. To compare this
  /// expression against two values, see
  Expression<bool, BoolType> isBetween(
      Expression<DT, ST> lower, Expression<DT, ST> higher,
      {bool not = false}) {
    return _BetweenExpression(
        target: this, lower: lower, higher: higher, not: not);
  }

  /// Returns an expression evaluating to true if this expression is between
  /// [lower] and [higher] (both inclusive).
  ///
  /// If [not] is set, the expression will be negated.
  Expression<bool, BoolType> isBetweenValues(DT lower, DT higher,
      {bool not = false}) {
    return _BetweenExpression(
      target: this,
      lower: Variable<DT, ST>(lower),
      higher: Variable<DT, ST>(higher),
      not: not,
    );
  }
}

class _BetweenExpression extends Expression<bool, BoolType> {
  final Expression target;

  // https://www.sqlite.org/lang_expr.html#between
  @override
  final Precedence precedence = Precedence.comparisonEq;

  /// Whether to negate this between expression
  final bool not;

  final Expression lower;
  final Expression higher;

  _BetweenExpression(
      {@required this.target,
      @required this.lower,
      @required this.higher,
      this.not = false});

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, target);

    if (not) context.buffer.write(' NOT');
    context.buffer.write(' BETWEEN ');

    writeInner(context, lower);
    context.buffer.write(' AND ');
    writeInner(context, higher);
  }

  @override
  int get hashCode => $mrjf($mrjc(target.hashCode,
      $mrjc(lower.hashCode, $mrjc(higher.hashCode, not.hashCode))));

  @override
  bool operator ==(dynamic other) {
    return other is _BetweenExpression &&
        other.target == target &&
        other.not == not &&
        other.lower == lower &&
        other.higher == higher;
  }
}
