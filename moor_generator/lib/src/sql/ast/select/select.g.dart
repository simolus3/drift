// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'select.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SelectStatement extends SelectStatement {
  @override
  final BuiltList<ResultColumn> columns;
  @override
  final BuiltList<SelectTarget> from;
  @override
  final Expression where;
  @override
  final Limit limit;

  factory _$SelectStatement([void Function(SelectStatementBuilder) updates]) =>
      (new SelectStatementBuilder()..update(updates)).build();

  _$SelectStatement._({this.columns, this.from, this.where, this.limit})
      : super._() {
    if (columns == null) {
      throw new BuiltValueNullFieldError('SelectStatement', 'columns');
    }
    if (from == null) {
      throw new BuiltValueNullFieldError('SelectStatement', 'from');
    }
  }

  @override
  SelectStatement rebuild(void Function(SelectStatementBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SelectStatementBuilder toBuilder() =>
      new SelectStatementBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SelectStatement &&
        columns == other.columns &&
        from == other.from &&
        where == other.where &&
        limit == other.limit;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, columns.hashCode), from.hashCode), where.hashCode),
        limit.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('SelectStatement')
          ..add('columns', columns)
          ..add('from', from)
          ..add('where', where)
          ..add('limit', limit))
        .toString();
  }
}

class SelectStatementBuilder
    implements Builder<SelectStatement, SelectStatementBuilder> {
  _$SelectStatement _$v;

  ListBuilder<ResultColumn> _columns;
  ListBuilder<ResultColumn> get columns =>
      _$this._columns ??= new ListBuilder<ResultColumn>();
  set columns(ListBuilder<ResultColumn> columns) => _$this._columns = columns;

  ListBuilder<SelectTarget> _from;
  ListBuilder<SelectTarget> get from =>
      _$this._from ??= new ListBuilder<SelectTarget>();
  set from(ListBuilder<SelectTarget> from) => _$this._from = from;

  Expression _where;
  Expression get where => _$this._where;
  set where(Expression where) => _$this._where = where;

  LimitBuilder _limit;
  LimitBuilder get limit => _$this._limit ??= new LimitBuilder();
  set limit(LimitBuilder limit) => _$this._limit = limit;

  SelectStatementBuilder();

  SelectStatementBuilder get _$this {
    if (_$v != null) {
      _columns = _$v.columns?.toBuilder();
      _from = _$v.from?.toBuilder();
      _where = _$v.where;
      _limit = _$v.limit?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SelectStatement other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$SelectStatement;
  }

  @override
  void update(void Function(SelectStatementBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$SelectStatement build() {
    _$SelectStatement _$result;
    try {
      _$result = _$v ??
          new _$SelectStatement._(
              columns: columns.build(),
              from: from.build(),
              where: where,
              limit: _limit?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'columns';
        columns.build();
        _$failedField = 'from';
        from.build();

        _$failedField = 'limit';
        _limit?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'SelectStatement', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$TableTarget extends TableTarget {
  @override
  final String table;

  factory _$TableTarget([void Function(TableTargetBuilder) updates]) =>
      (new TableTargetBuilder()..update(updates)).build();

  _$TableTarget._({this.table}) : super._() {
    if (table == null) {
      throw new BuiltValueNullFieldError('TableTarget', 'table');
    }
  }

  @override
  TableTarget rebuild(void Function(TableTargetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TableTargetBuilder toBuilder() => new TableTargetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TableTarget && table == other.table;
  }

  @override
  int get hashCode {
    return $jf($jc(0, table.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('TableTarget')..add('table', table))
        .toString();
  }
}

class TableTargetBuilder implements Builder<TableTarget, TableTargetBuilder> {
  _$TableTarget _$v;

  String _table;
  String get table => _$this._table;
  set table(String table) => _$this._table = table;

  TableTargetBuilder();

  TableTargetBuilder get _$this {
    if (_$v != null) {
      _table = _$v.table;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TableTarget other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$TableTarget;
  }

  @override
  void update(void Function(TableTargetBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$TableTarget build() {
    final _$result = _$v ?? new _$TableTarget._(table: table);
    replace(_$result);
    return _$result;
  }
}

class _$Limit extends Limit {
  @override
  final Expression amount;
  @override
  final Expression offset;

  factory _$Limit([void Function(LimitBuilder) updates]) =>
      (new LimitBuilder()..update(updates)).build();

  _$Limit._({this.amount, this.offset}) : super._() {
    if (amount == null) {
      throw new BuiltValueNullFieldError('Limit', 'amount');
    }
  }

  @override
  Limit rebuild(void Function(LimitBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LimitBuilder toBuilder() => new LimitBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Limit && amount == other.amount && offset == other.offset;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, amount.hashCode), offset.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Limit')
          ..add('amount', amount)
          ..add('offset', offset))
        .toString();
  }
}

class LimitBuilder implements Builder<Limit, LimitBuilder> {
  _$Limit _$v;

  Expression _amount;
  Expression get amount => _$this._amount;
  set amount(Expression amount) => _$this._amount = amount;

  Expression _offset;
  Expression get offset => _$this._offset;
  set offset(Expression offset) => _$this._offset = offset;

  LimitBuilder();

  LimitBuilder get _$this {
    if (_$v != null) {
      _amount = _$v.amount;
      _offset = _$v.offset;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Limit other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Limit;
  }

  @override
  void update(void Function(LimitBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Limit build() {
    final _$result = _$v ?? new _$Limit._(amount: amount, offset: offset);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
