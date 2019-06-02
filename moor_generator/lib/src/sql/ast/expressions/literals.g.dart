// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'literals.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BooleanLiteral extends BooleanLiteral {
  @override
  final bool value;

  factory _$BooleanLiteral([void Function(BooleanLiteralBuilder) updates]) =>
      (new BooleanLiteralBuilder()..update(updates)).build();

  _$BooleanLiteral._({this.value}) : super._() {
    if (value == null) {
      throw new BuiltValueNullFieldError('BooleanLiteral', 'value');
    }
  }

  @override
  BooleanLiteral rebuild(void Function(BooleanLiteralBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BooleanLiteralBuilder toBuilder() =>
      new BooleanLiteralBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BooleanLiteral && value == other.value;
  }

  @override
  int get hashCode {
    return $jf($jc(0, value.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BooleanLiteral')..add('value', value))
        .toString();
  }
}

class BooleanLiteralBuilder
    implements Builder<BooleanLiteral, BooleanLiteralBuilder> {
  _$BooleanLiteral _$v;

  bool _value;
  bool get value => _$this._value;
  set value(bool value) => _$this._value = value;

  BooleanLiteralBuilder();

  BooleanLiteralBuilder get _$this {
    if (_$v != null) {
      _value = _$v.value;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BooleanLiteral other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$BooleanLiteral;
  }

  @override
  void update(void Function(BooleanLiteralBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$BooleanLiteral build() {
    final _$result = _$v ?? new _$BooleanLiteral._(value: value);
    replace(_$result);
    return _$result;
  }
}

class _$CurrentTimeResolver extends CurrentTimeResolver {
  @override
  final CurrentTimeAccessor mode;

  factory _$CurrentTimeResolver(
          [void Function(CurrentTimeResolverBuilder) updates]) =>
      (new CurrentTimeResolverBuilder()..update(updates)).build();

  _$CurrentTimeResolver._({this.mode}) : super._() {
    if (mode == null) {
      throw new BuiltValueNullFieldError('CurrentTimeResolver', 'mode');
    }
  }

  @override
  CurrentTimeResolver rebuild(
          void Function(CurrentTimeResolverBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CurrentTimeResolverBuilder toBuilder() =>
      new CurrentTimeResolverBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CurrentTimeResolver && mode == other.mode;
  }

  @override
  int get hashCode {
    return $jf($jc(0, mode.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('CurrentTimeResolver')
          ..add('mode', mode))
        .toString();
  }
}

class CurrentTimeResolverBuilder
    implements Builder<CurrentTimeResolver, CurrentTimeResolverBuilder> {
  _$CurrentTimeResolver _$v;

  CurrentTimeAccessor _mode;
  CurrentTimeAccessor get mode => _$this._mode;
  set mode(CurrentTimeAccessor mode) => _$this._mode = mode;

  CurrentTimeResolverBuilder();

  CurrentTimeResolverBuilder get _$this {
    if (_$v != null) {
      _mode = _$v.mode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CurrentTimeResolver other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$CurrentTimeResolver;
  }

  @override
  void update(void Function(CurrentTimeResolverBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$CurrentTimeResolver build() {
    final _$result = _$v ?? new _$CurrentTimeResolver._(mode: mode);
    replace(_$result);
    return _$result;
  }
}

class _$NumericLiteral extends NumericLiteral {
  @override
  final num value;

  factory _$NumericLiteral([void Function(NumericLiteralBuilder) updates]) =>
      (new NumericLiteralBuilder()..update(updates)).build();

  _$NumericLiteral._({this.value}) : super._() {
    if (value == null) {
      throw new BuiltValueNullFieldError('NumericLiteral', 'value');
    }
  }

  @override
  NumericLiteral rebuild(void Function(NumericLiteralBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NumericLiteralBuilder toBuilder() =>
      new NumericLiteralBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NumericLiteral && value == other.value;
  }

  @override
  int get hashCode {
    return $jf($jc(0, value.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('NumericLiteral')..add('value', value))
        .toString();
  }
}

class NumericLiteralBuilder
    implements Builder<NumericLiteral, NumericLiteralBuilder> {
  _$NumericLiteral _$v;

  num _value;
  num get value => _$this._value;
  set value(num value) => _$this._value = value;

  NumericLiteralBuilder();

  NumericLiteralBuilder get _$this {
    if (_$v != null) {
      _value = _$v.value;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NumericLiteral other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$NumericLiteral;
  }

  @override
  void update(void Function(NumericLiteralBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$NumericLiteral build() {
    final _$result = _$v ?? new _$NumericLiteral._(value: value);
    replace(_$result);
    return _$result;
  }
}

class _$StringLiteral extends StringLiteral {
  @override
  final bool isBlob;
  @override
  final String content;

  factory _$StringLiteral([void Function(StringLiteralBuilder) updates]) =>
      (new StringLiteralBuilder()..update(updates)).build();

  _$StringLiteral._({this.isBlob, this.content}) : super._() {
    if (isBlob == null) {
      throw new BuiltValueNullFieldError('StringLiteral', 'isBlob');
    }
    if (content == null) {
      throw new BuiltValueNullFieldError('StringLiteral', 'content');
    }
  }

  @override
  StringLiteral rebuild(void Function(StringLiteralBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StringLiteralBuilder toBuilder() => new StringLiteralBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StringLiteral &&
        isBlob == other.isBlob &&
        content == other.content;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, isBlob.hashCode), content.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('StringLiteral')
          ..add('isBlob', isBlob)
          ..add('content', content))
        .toString();
  }
}

class StringLiteralBuilder
    implements Builder<StringLiteral, StringLiteralBuilder> {
  _$StringLiteral _$v;

  bool _isBlob;
  bool get isBlob => _$this._isBlob;
  set isBlob(bool isBlob) => _$this._isBlob = isBlob;

  String _content;
  String get content => _$this._content;
  set content(String content) => _$this._content = content;

  StringLiteralBuilder();

  StringLiteralBuilder get _$this {
    if (_$v != null) {
      _isBlob = _$v.isBlob;
      _content = _$v.content;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StringLiteral other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$StringLiteral;
  }

  @override
  void update(void Function(StringLiteralBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$StringLiteral build() {
    final _$result =
        _$v ?? new _$StringLiteral._(isBlob: isBlob, content: content);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
