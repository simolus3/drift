// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Foo extends Foo {
  @override
  final User moorField;

  factory _$Foo([void Function(FooBuilder)? updates]) =>
      (new FooBuilder()..update(updates))._build();

  _$Foo._({required this.moorField}) : super._() {
    BuiltValueNullFieldError.checkNotNull(moorField, r'Foo', 'moorField');
  }

  @override
  Foo rebuild(void Function(FooBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FooBuilder toBuilder() => new FooBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Foo && moorField == other.moorField;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, moorField.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Foo')..add('moorField', moorField))
        .toString();
  }
}

class FooBuilder implements Builder<Foo, FooBuilder> {
  _$Foo? _$v;

  User? _moorField;
  User? get moorField => _$this._moorField;
  set moorField(User? moorField) => _$this._moorField = moorField;

  FooBuilder();

  FooBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _moorField = $v.moorField;
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
            moorField: BuiltValueNullFieldError.checkNotNull(
                moorField, r'Foo', 'moorField'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
