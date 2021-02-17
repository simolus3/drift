part of '../query_builder.dart';

class _ExistsExpression<T> extends Expression<bool> {
  final BaseSelectStatement _select;
  final bool _not;

  @override
  Precedence get precedence => Precedence.comparisonEq;

  _ExistsExpression(this._select, this._not);

  @override
  void writeInto(GenerationContext context) {
    if (_not) {
      context.buffer.write('NOT ');
    }
    context.buffer.write('EXISTS ');

    context.buffer.write('(');

    _select.writeInto(context);

    context.buffer.write(')');
  }

  @override
  int get hashCode => $mrjf($mrjc(_select.hashCode, _not.hashCode));

  @override
  bool operator ==(dynamic other) {
    return other is _ExistsExpression &&
        other._select == _select &&
        other._not == _not;
  }
}
