// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Foo extends Foo {
  @override
  final User moorField;

  factory _$Foo([void Function(FooBuilder) updates]) =>
      (new FooBuilder()..update(updates)).build();

  _$Foo._({this.moorField}) : super._() {
    BuiltValueNullFieldError.checkNotNull(moorField, 'Foo', 'moorField');
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
    return $jf($jc(0, moorField.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Foo')..add('moorField', moorField))
        .toString();
  }
}

class FooBuilder implements Builder<Foo, FooBuilder> {
  _$Foo _$v;

  User _moorField;
  User get moorField => _$this._moorField;
  set moorField(User moorField) => _$this._moorField = moorField;

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
  void update(void Function(FooBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Foo build() {
    final _$result = _$v ??
        new _$Foo._(
            moorField: BuiltValueNullFieldError.checkNotNull(
                moorField, 'Foo', 'moorField'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
