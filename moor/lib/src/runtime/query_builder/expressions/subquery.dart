part of '../query_builder.dart';

class _ExistsExpression<T> extends Expression<bool> {
  final Subquery _subquery;
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

    context.buffer.write(subqueryContext.sql);
    for (final variable in subqueryContext.introducedVariables) {
      context.introduceVariable(variable, variable.value);
    }

    context.buffer.write(')');
  }

  @override
  int get hashCode => $mrjf($mrjc(_subquery.hashCode, _not.hashCode));

  @override
  bool operator ==(dynamic other) {
    return other is _ExistsExpression &&
        other._subquery == _subquery &&
        other._not == _not;
  }
}

class Subquery<T extends Table, D extends DataClass> extends Query<T, D> {
  final Query<T, D> _delegate;

  @override
  DatabaseConnectionUser get database => _delegate.database;

  @override
  TableInfo<T, D> get table => _delegate.table;

  @override
  Where? get whereExpr => _delegate.whereExpr;

  @override
  OrderBy? get orderByExpr => _delegate.orderByExpr;

  @override
  Limit? get limitExpr => _delegate.limitExpr;

  @override
  GroupBy? get _groupBy => _delegate._groupBy;

  Subquery(this._delegate)
      : super(
          _delegate.database,
          _delegate.table,
        );

  @override
  void writeStartPart(GenerationContext ctx) {
    return _delegate.writeStartPart(ctx);
  }

  @override
  GenerationContext constructQuery() {
    final context = super.constructQuery();
    final sql = context.sql;
    context.buffer.clear();
    // Remove the semicolon
    context.buffer.write(sql.substring(0, sql.length - 1));
    return context;
  }
}
