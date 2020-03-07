part of '../query_builder.dart';

class _InExpression<T> extends Expression<bool> {
  final Expression<T> _expression;
  final List<T> _values;
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
    for (final value in _values) {
      final variable = Variable<T>(value);

      if (first) {
        first = false;
      } else {
        context.buffer.write(', ');
      }

      variable.writeInto(context);
    }

    context.buffer.write(')');
  }

  @override
  int get hashCode => $mrjf($mrjc(
      _expression.hashCode, $mrjc(_equality.hash(_values), _not.hashCode)));

  @override
  bool operator ==(dynamic other) {
    return other is _InExpression &&
        other._expression == _expression &&
        other._values == _values &&
        other._not == _not;
  }
}
