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

enum CastMode { numeric, boolean }

/// Dependency declaring that [target] has the same type as [other] after
/// casting it with [cast].
class CopyAndCast extends TypeRelationship {
  final Typeable target;
  final Typeable other;
  final CastMode cast;

  CopyAndCast(this.target, this.other, this.cast);
}
