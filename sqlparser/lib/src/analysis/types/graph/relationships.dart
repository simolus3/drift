part of '../types.dart';

/// Dependency declaring that [target] is nullable if any in [from] is
/// nullable.
class NullableIfSomeOtherIs extends TypeRelation
    implements MultiSourceRelation {
  @override
  final Typeable target;
  @override
  final List<Typeable> from;

  NullableIfSomeOtherIs(this.target, this.from);
}

/// Dependency declaring that [target] has exactly the same type as [other].
class CopyTypeFrom extends TypeRelation implements DirectedRelation {
  @override
  final Typeable target;
  final Typeable other;

  /// When true, [target] will be the array-variant of [other]. When false,
  /// [target] will be the scalar variant of [other]. When null, nothing will be
  /// transformed.
  final bool? array;

  /// Whether [target] is the nullable version of [other].
  final bool makeNullable;

  CopyTypeFrom(this.target, this.other,
      {this.array, this.makeNullable = false});
}

/// Dependency declaring that [target] has a type that matches all of [from].
class CopyEncapsulating extends TypeRelation implements MultiSourceRelation {
  @override
  final Typeable target;
  @override
  final List<Typeable> from;

  final CastMode? cast;
  final EncapsulatingNullability nullability;

  CopyEncapsulating(this.target, this.from,
      [this.cast, this.nullability = EncapsulatingNullability.nullIfAny]);
}

/// Dependency declaring that [elements] all have the same type. This is
/// an optional dependency that will only be applied when one type is known and
/// the others are not.
class HaveSameType extends TypeRelation {
  final List<Typeable> elements;

  HaveSameType(this.elements);

  Iterable<Typeable> getOthers(Typeable t) {
    assert(elements.contains(t));
    return elements.where((e) => e != t);
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

enum EncapsulatingNullability {
  nullIfAny,
  nullIfAll,
}

/// Dependency declaring that [target] has the same type as [other] after
/// casting it with [cast].
class CopyAndCast extends TypeRelation implements DirectedRelation {
  @override
  final Typeable target;
  final Typeable other;
  final CastMode cast;
  final bool dropTypeHint;

  CopyAndCast(this.target, this.other, this.cast, {this.dropTypeHint = false});
}
