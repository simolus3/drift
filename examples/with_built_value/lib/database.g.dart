// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Foo extends Foo {
  @override
  final User driftGeneratedField;

  factory _$Foo([void Function(FooBuilder)? updates]) =>
      (new FooBuilder()..update(updates))._build();

  _$Foo._({required this.driftGeneratedField}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
        driftGeneratedField, r'Foo', 'driftGeneratedField');
  }

  @override
  Foo rebuild(void Function(FooBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FooBuilder toBuilder() => new FooBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Foo && driftGeneratedField == other.driftGeneratedField;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, driftGeneratedField.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Foo')
          ..add('driftGeneratedField', driftGeneratedField))
        .toString();
  }
}

class FooBuilder implements Builder<Foo, FooBuilder> {
  _$Foo? _$v;

  User? _driftGeneratedField;
  User? get driftGeneratedField => _$this._driftGeneratedField;
  set driftGeneratedField(User? driftGeneratedField) =>
      _$this._driftGeneratedField = driftGeneratedField;

  FooBuilder();

  FooBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driftGeneratedField = $v.driftGeneratedField;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Foo other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Foo;
  }

  @override
  void update(void Function(FooBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Foo build() => _build();

  _$Foo _build() {
    final _$result = _$v ??
        new _$Foo._(
            driftGeneratedField: BuiltValueNullFieldError.checkNotNull(
                driftGeneratedField, r'Foo', 'driftGeneratedField'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
