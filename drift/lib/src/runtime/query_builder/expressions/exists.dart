part of '../query_builder.dart';

/// The `EXISTS` operator checks whether the [select] subquery returns any rows.
Expression<bool> existsQuery(BaseSelectStatement select) {
  return _ExistsExpression(select, false);
}

/// The `NOT EXISTS` operator evaluates to `true` if the [select] subquery does
/// not return any rows.
Expression<bool> notExistsQuery(BaseSelectStatement select) {
  return _ExistsExpression(select, true);
}

class _ExistsExpression<T> extends Expression<bool> {
  final BaseSelectStatement _select;
  final bool _not;

  @override
  Precedence get precedence => Precedence.comparisonEq;

  _ExistsExpression(this._select, this._not);

  @override
  void writeInto(GenerationContext context) {
    final outerHasMultipleTables = context.hasMultipleTables;
    // Inside this subquery, we want to reference columns with their table
    // to avoid ambiguities when an outer table is referenced.
    context.hasMultipleTables = true;
    if (_not) {
      context.buffer.write('NOT ');
    }
    context.buffer.write('EXISTS ');

    context.buffer.write('(');
    _select.writeInto(context);
    context.buffer.write(')');
    context.hasMultipleTables = outerHasMultipleTables;
  }

  @override
  int get hashCode => Object.hash(_select, _not);

  @override
  bool operator ==(Object other) {
    return other is _ExistsExpression &&
        other._select == _select &&
        other._not == _not;
  }
}
