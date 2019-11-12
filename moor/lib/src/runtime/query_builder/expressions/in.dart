part of '../query_builder.dart';

/// An expression that is true if the given [expression] resolves to any of the
/// values in [values].
@Deprecated('Use Expression.isIn instead')
Expression<bool, BoolType> isIn<X extends SqlType<T>, T>(
    Expression<T, X> expression, Iterable<T> values,
    {bool not = false}) {
  if (not == true) {
    return expression.isNotIn(values);
  } else {
    return expression.isIn(values);
  }
}

/// An expression that is true if the given [expression] does not resolve to any
/// of the values in [values].
@Deprecated('Use Expression.isNotIn instead')
Expression<bool, BoolType> isNotIn<X extends SqlType<T>, T>(
        Expression<T, X> expression, Iterable<T> values) =>
    isIn(expression, values, not: true);

class _InExpression<X extends SqlType<T>, T>
    extends Expression<bool, BoolType> {
  final Expression<T, X> _expression;
  final Iterable<T> _values;
  final bool _not;

  @override
  Precedence get precedence => Precedence.comparisonEq;

  _InExpression(this._expression, this._values, this._not);

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, _expression);

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
