part of '../query_builder.dart';

class _ExistsExpression<T> extends Expression<bool> {
  final Query _subquery;
  final bool _not;

  @override
  Precedence get precedence => Precedence.comparisonEq;

  _ExistsExpression(this._subquery, this._not);

  @override
  void writeInto(GenerationContext context) {

    if (_not) {
      context.buffer.write('NOT ');
    }
    context.buffer.write('EXISTS ');

    context.buffer.write('(');

    final subqueryContext = _subquery.constructQuery();

    final subquerySql = subqueryContext.sql.substring(
      0,
      subqueryContext.sql.length - 1,
    );
    context.buffer.write(subquerySql);
    for (final variable in subqueryContext.introducedVariables) {
      context.introduceVariable(variable, variable.value);
    }

    context.buffer.write(')');
  }

  @override
  int get hashCode => $mrjf(
      $mrjc(_subquery.hashCode, _not.hashCode));

  @override
  bool operator ==(dynamic other) {
    return other is _ExistsExpression &&
        other._subquery == _subquery &&
        other._not == _not;
  }
}
