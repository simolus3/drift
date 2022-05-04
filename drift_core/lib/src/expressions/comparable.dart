import '../builder/context.dart';
import 'common.dart';
import 'expression.dart';

/// Defines extension functions to express comparisons in sql
extension ComparableExpr<T extends Comparable<Object?>> on Expression<T> {
  /// Returns an expression that is true if this expression is strictly greater
  /// than the other expression.
  Expression<bool> greaterThan(Expression<T> other) {
    return BinaryExpression(this, '>', other,
        precedence: Precedence.comparison);
  }

  /// Returns an expression that is true if this expression is greater than or
  /// equal to he other expression.
  Expression<bool> greaterThanOrEqual(Expression<T> other) {
    return BinaryExpression(this, '>=', other,
        precedence: Precedence.comparison);
  }

  /// Returns an expression that is true if this expression is strictly smaller
  /// than the other expression.
  Expression<bool> lessThan(Expression<T> other) {
    return BinaryExpression(this, '<', other,
        precedence: Precedence.comparison);
  }

  /// Returns an expression that is true if this expression is smaller than or
  /// equal to he other expression.
  Expression<bool> lessThanOrEqual(Expression<T> other) {
    return BinaryExpression(this, '<=', other,
        precedence: Precedence.comparison);
  }

  /// Returns an expression evaluating to true if this expression is between
  /// [lower] and [higher] (both inclusive).
  ///
  /// If [not] is set, the expression will be negated. To compare this
  /// expression against two values, see
  Expression<bool> between(Expression<T> lower, Expression<T> higher,
      {bool not = false}) {
    return _BetweenExpression(
        target: this, lower: lower, higher: higher, not: not);
  }
}

class _BetweenExpression extends Expression<bool> {
  final Expression target;

  // https://www.sqlite.org/lang_expr.html#between
  @override
  Precedence get precedence => Precedence.comparisonEq;

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
