// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'specified_column.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ColumnName extends ColumnName {
  @override
  final bool implicit;
  @override
  final String name;

  factory _$ColumnName([void updates(ColumnNameBuilder b)]) =>
      (new ColumnNameBuilder()..update(updates)).build();

  _$ColumnName._({this.implicit, this.name}) : super._() {
    if (implicit == null) {
      throw new BuiltValueNullFieldError('ColumnName', 'implicit');
    }
    if (name == null) {
      throw new BuiltValueNullFieldError('ColumnName', 'name');
    }
  }

  @override
  ColumnName rebuild(void updates(ColumnNameBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  ColumnNameBuilder toBuilder() => new ColumnNameBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ColumnName &&
        implicit == other.implicit &&
        name == other.name;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, implicit.hashCode), name.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ColumnName')
          ..add('implicit', implicit)
          ..add('name', name))
        .toString();
  }
}

class ColumnNameBuilder implements Builder<ColumnName, ColumnNameBuilder> {
  _$ColumnName _$v;

  bool _implicit;
  bool get implicit => _$this._implicit;
  set implicit(bool implicit) => _$this._implicit = implicit;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  ColumnNameBuilder();

  ColumnNameBuilder get _$this {
    if (_$v != null) {
      _implicit = _$v.implicit;
      _name = _$v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ColumnName other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ColumnName;
  }

  @override
  void update(void updates(ColumnNameBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$ColumnName build() {
    final _$result = _$v ?? new _$ColumnName._(implicit: implicit, name: name);
    replace(_$result);
    return _$result;
  }
}

class _$LimitingTextLength extends LimitingTextLength {
  @override
  final int minLength;
  @override
  final int maxLength;

  factory _$LimitingTextLength([void updates(LimitingTextLengthBuilder b)]) =>
      (new LimitingTextLengthBuilder()..update(updates)).build();

  _$LimitingTextLength._({this.minLength, this.maxLength}) : super._();

  @override
  LimitingTextLength rebuild(void updates(LimitingTextLengthBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  LimitingTextLengthBuilder toBuilder() =>
      new LimitingTextLengthBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LimitingTextLength &&
        minLength == other.minLength &&
        maxLength == other.maxLength;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, minLength.hashCode), maxLength.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LimitingTextLength')
          ..add('minLength', minLength)
          ..add('maxLength', maxLength))
        .toString();
  }
}

class LimitingTextLengthBuilder
    implements Builder<LimitingTextLength, LimitingTextLengthBuilder> {
  _$LimitingTextLength _$v;

  int _minLength;
  int get minLength => _$this._minLength;
  set minLength(int minLength) => _$this._minLength = minLength;

  int _maxLength;
  int get maxLength => _$this._maxLength;
  set maxLength(int maxLength) => _$this._maxLength = maxLength;

  LimitingTextLengthBuilder();

  LimitingTextLengthBuilder get _$this {
    if (_$v != null) {
      _minLength = _$v.minLength;
      _maxLength = _$v.maxLength;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LimitingTextLength other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$LimitingTextLength;
  }

  @override
  void update(void updates(LimitingTextLengthBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$LimitingTextLength build() {
    final _$result = _$v ??
        new _$LimitingTextLength._(minLength: minLength, maxLength: maxLength);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
