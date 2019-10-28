part of '../query_builder.dart';

/// An expression that is true if the given [expression] resolves to any of the
/// values in [values].
Expression<bool, BoolType> isIn<X extends SqlType<T>, T>(
    Expression<T, X> expression, Iterable<T> values,
    {bool not = false}) {
  return _InExpression(expression, values, not);
}

/// An expression that is true if the given [expression] does not resolve to any
/// of the values in [values].
Expression<bool, BoolType> isNotIn<X extends SqlType<T>, T>(
        Expression<T, X> expression, Iterable<T> values) =>
    isIn(expression, values, not: true);

class _InExpression<X extends SqlType<T>, T>
    extends Expression<bool, BoolType> {
  final Expression<T, X> _expression;
  final Iterable<T> _values;
  final bool _not;

  _InExpression(this._expression, this._values, this._not);

  @override
  void writeInto(GenerationContext context) {
    _expression.writeInto(context);

    if (_not) {
      context.buffer.write(' NOT');
    }
    context.buffer.write(' IN ');

    context.buffer.write('(');

    var first = true;
    for (var value in _values) {
      final variable = Variable<T, X>(value);

      if (first) {
        first = false;
      } else {
        context.buffer.write(', ');
      }

      variable.writeInto(context);
    }

    context.buffer.write(')');
  }
}
