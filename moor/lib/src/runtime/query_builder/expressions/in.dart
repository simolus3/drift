part of '../query_builder.dart';

abstract class _BaseInExpression extends Expression<bool?> {
  final Expression _expression;
  final bool _not;

  _BaseInExpression(this._expression, this._not);

  @override
  Precedence get precedence => Precedence.comparisonEq;

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, _expression);

    if (_not) {
      context.buffer.write(' NOT');
    }
    context.buffer.write(' IN (');

    _writeValues(context);
    context.buffer.write(')');
  }

  void _writeValues(GenerationContext context);
}

class _InExpression<T> extends _BaseInExpression {
  final List<T> _values;

  _InExpression(Expression expression, this._values, bool not)
      : super(expression, not);

  @override
  void _writeValues(GenerationContext context) {
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
  }

  @override
  int get hashCode => $mrjf($mrjc(
      _expression.hashCode, $mrjc(_equality.hash(_values), _not.hashCode)));

  @override
  bool operator ==(Object other) {
    return other is _InExpression &&
        other._expression == _expression &&
        _equality.equals(other._values, _values) &&
        other._not == _not;
  }
}

class _InSelectExpression extends _BaseInExpression {
  final BaseSelectStatement _select;

  _InSelectExpression(this._select, Expression expression, bool not)
      : super(expression, not);

  @override
  void _writeValues(GenerationContext context) {
    _select.writeInto(context);
  }

  @override
  int get hashCode => $mrjf(
      $mrjc(_expression.hashCode, $mrjc(_select.hashCode, _not.hashCode)));

  @override
  bool operator ==(Object other) {
    return other is _InSelectExpression &&
        other._expression == _expression &&
        other._select == _select &&
        other._not == _not;
  }
}
