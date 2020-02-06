// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Foo extends Foo {
  @override
  final SomeInt moorField;

  factory _$Foo([void Function(FooBuilder) updates]) =>
      (new FooBuilder()..update(updates)).build();

  _$Foo._({this.moorField}) : super._() {
    if (moorField == null) {
      throw new BuiltValueNullFieldError('Foo', 'moorField');
    }
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

  SomeInt _moorField;
  SomeInt get moorField => _$this._moorField;
  set moorField(SomeInt moorField) => _$this._moorField = moorField;

  FooBuilder();

  FooBuilder get _$this {
    if (_$v != null) {
      _moorField = _$v.moorField;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Foo other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Foo;
  }

  @override
  void update(void Function(FooBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Foo build() {
    final _$result = _$v ?? new _$Foo._(moorField: moorField);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
