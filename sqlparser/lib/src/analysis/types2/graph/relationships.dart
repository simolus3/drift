part of '../types.dart';

/// Dependency declaring that [target] is nullable if any in [from] is
/// nullable.
class NullableIfSomeOtherIs extends TypeRelation
    implements MultiSourceRelation {
  @override
  final Typeable target;
  @override
  final List<Typeable?> from;

  NullableIfSomeOtherIs(this.target, this.from);
}

/// Dependency declaring that [target] has exactly the same type as [other].
class CopyTypeFrom extends TypeRelation implements DirectedRelation {
  @override
  final Typeable target;
  final Typeable? other;

  /// When true, [target] will be the array-variant of [other]. When false,
  /// [target] will be the scalar variant of [other]. When null, nothing will be
  /// transformed.
  final bool? array;

  CopyTypeFrom(this.target, this.other, {this.array});
}

/// Dependency declaring that [target] has a type that matches all of [from].
class CopyEncapsulating extends TypeRelation implements MultiSourceRelation {
  @override
  final Typeable? target;
  @override
  final List<Typeable?> from;

  final CastMode? cast;

  CopyEncapsulating(this.target, this.from, [this.cast]);
}

/// Dependency declaring that [first] and [second] have the same type. This is
/// an optional dependency that will only be applied when one type is known and
/// the other is not.
class HaveSameType extends TypeRelation {
  final Typeable first;
  final Typeable second;

  HaveSameType(this.first, this.second);

  Typeable getOther(Typeable? t) {
    assert(t == first || t == second);
    return t == first ? second : first;
  }
}

/// Dependency declaring that, if no better option is found, [target] should
/// have the specified [defaultType].
class DefaultType extends TypeRelation implements DirectedRelation {
  @override
  final Typeable target;
  final ResolvedType? defaultType;
  final bool? isNullable;

  DefaultType(this.target, {this.defaultType, this.isNullable});
}

enum CastMode {
  numeric,

  /// Like [numeric], but assume [BasicType.int] if the resulting type doesn't
  /// match.
  numericPreferInt,
  boolean,
}

/// Dependency declaring that [target] has the same type as [other] after
/// casting it with [cast].
class CopyAndCast extends TypeRelation implements DirectedRelation {
  @override
  final Typeable target;
  final Typeable other;
  final CastMode cast;

  CopyAndCast(this.target, this.other, this.cast);
}
