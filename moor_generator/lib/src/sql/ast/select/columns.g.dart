// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'columns.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExprResultColumn extends ExprResultColumn {
  @override
  final Expression expr;
  @override
  final String alias;

  factory _$ExprResultColumn(
          [void Function(ExprResultColumnBuilder) updates]) =>
      (new ExprResultColumnBuilder()..update(updates)).build();

  _$ExprResultColumn._({this.expr, this.alias}) : super._() {
    if (expr == null) {
      throw new BuiltValueNullFieldError('ExprResultColumn', 'expr');
    }
  }

  @override
  ExprResultColumn rebuild(void Function(ExprResultColumnBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExprResultColumnBuilder toBuilder() =>
      new ExprResultColumnBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExprResultColumn &&
        expr == other.expr &&
        alias == other.alias;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, expr.hashCode), alias.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ExprResultColumn')
          ..add('expr', expr)
          ..add('alias', alias))
        .toString();
  }
}

class ExprResultColumnBuilder
    implements Builder<ExprResultColumn, ExprResultColumnBuilder> {
  _$ExprResultColumn _$v;

  Expression _expr;
  Expression get expr => _$this._expr;
  set expr(Expression expr) => _$this._expr = expr;

  String _alias;
  String get alias => _$this._alias;
  set alias(String alias) => _$this._alias = alias;

  ExprResultColumnBuilder();

  ExprResultColumnBuilder get _$this {
    if (_$v != null) {
      _expr = _$v.expr;
      _alias = _$v.alias;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExprResultColumn other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ExprResultColumn;
  }

  @override
  void update(void Function(ExprResultColumnBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ExprResultColumn build() {
    final _$result = _$v ?? new _$ExprResultColumn._(expr: expr, alias: alias);
    replace(_$result);
    return _$result;
  }
}

class _$StarResultColumn extends StarResultColumn {
  @override
  final String table;

  factory _$StarResultColumn(
          [void Function(StarResultColumnBuilder) updates]) =>
      (new StarResultColumnBuilder()..update(updates)).build();

  _$StarResultColumn._({this.table}) : super._();

  @override
  StarResultColumn rebuild(void Function(StarResultColumnBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StarResultColumnBuilder toBuilder() =>
      new StarResultColumnBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StarResultColumn && table == other.table;
  }

  @override
  int get hashCode {
    return $jf($jc(0, table.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('StarResultColumn')
          ..add('table', table))
        .toString();
  }
}

class StarResultColumnBuilder
    implements Builder<StarResultColumn, StarResultColumnBuilder> {
  _$StarResultColumn _$v;

  String _table;
  String get table => _$this._table;
  set table(String table) => _$this._table = table;

  StarResultColumnBuilder();

  StarResultColumnBuilder get _$this {
    if (_$v != null) {
      _table = _$v.table;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StarResultColumn other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$StarResultColumn;
  }

  @override
  void update(void Function(StarResultColumnBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$StarResultColumn build() {
    final _$result = _$v ?? new _$StarResultColumn._(table: table);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
