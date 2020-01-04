part of '../types.dart';

/// Dependency declaring that [target] is nullable if any in [other] is
/// nullable.
class NullableIfSomeOtherIs extends TypeRelationship {
  final Typeable target;
  final List<Typeable> other;

  NullableIfSomeOtherIs(this.target, this.other);
}

/// Dependency declaring that [target] has exactly the same type as [other].
class CopyTypeFrom extends TypeRelationship {
  final Typeable target;
  final Typeable other;

  CopyTypeFrom(this.target, this.other);
}

/// Dependency declaring that [target] has a type that matches all of [from].
class CopyEncapsulating extends TypeRelationship {
  final Typeable target;
  final List<Typeable> from;

  CopyEncapsulating(this.target, this.from);
}

/// Dependency declaring that [first] and [second] have the same type. This is
/// an optional dependency that will only be applied when one type is known and
/// the other is not.
class HaveSameType extends TypeRelationship {
  final Typeable first;
  final Typeable second;

  HaveSameType(this.first, this.second);

  Typeable getOther(Typeable t) {
    assert(t == first || t == second);
    return t == first ? second : first;
  }
}

/// Dependency declaring that, if no better option is found, [target] should
/// have the specified [defaultType].
class DefaultType extends TypeRelationship {
  final Typeable target;
  final ResolvedType defaultType;

  DefaultType(this.target, this.defaultType);
}

enum CastMode { numeric, boolean }

/// Dependency declaring that [target] has the same type as [other] after
/// casting it with [cast].
class CopyAndCast extends TypeRelationship {
  final Typeable target;
  final Typeable other;
  final CastMode cast;

  CopyAndCast(this.target, this.other, this.cast);
}
