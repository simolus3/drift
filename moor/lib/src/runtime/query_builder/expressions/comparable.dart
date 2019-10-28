part of '../query_builder.dart';

// todo: Can we replace these classes with an extension on expression?

/// An [Expression] that operates on ints. Declared as a class so that we can
/// mixin [ComparableExpr].
abstract class IntExpression extends Expression<int, IntType>
    implements ComparableExpr<int, IntType> {}

/// An [Expression] that operates on doubles. Declared as a class so that we can
/// mixin [ComparableExpr].
abstract class DoubleExpression extends Expression<double, RealType>
    implements ComparableExpr<double, RealType> {}

/// An [Expression] that operates on datetimes. Declared as a class so that we
/// can mixin [ComparableExpr].
abstract class DateTimeExpression extends Expression<DateTime, DateTimeType>
    implements ComparableExpr<DateTime, DateTimeType> {}

mixin ComparableExpr<DT, ST extends SqlType<DT>> on Expression<DT, ST> {
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
    target.writeInto(context);

    if (not) context.buffer.write(' NOT');
    context.buffer.write(' BETWEEN ');

    lower.writeInto(context);
    context.buffer.write(' AND ');
    higher.writeInto(context);
  }
}
