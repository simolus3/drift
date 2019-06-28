part of '../analysis.dart';

/// A type that sql expressions can have at runtime.
enum BasicType {
  nullType,
  int,
  real,
  text,
  blob,
}

class ResolvedType {
  final BasicType type;
  final TypeHint hint;
  final bool nullable;

  const ResolvedType({this.type, this.hint, this.nullable = false});
  const ResolvedType.bool()
      : this(type: BasicType.int, hint: const IsBoolean());

  ResolvedType withNullable(bool nullable) {
    return ResolvedType(type: type, hint: hint, nullable: nullable);
  }

  @override
  bool operator ==(other) {
    return identical(this, other) ||
        other is ResolvedType &&
            other.type == type &&
            other.hint == hint &&
            other.nullable == nullable;
  }

  @override
  int get hashCode {
    return type.hashCode + hint.hashCode + nullable.hashCode;
  }
}

/// Provides more precise hints than the [BasicType]. For instance, booleans are
/// stored as ints in sqlite, but it might be desirable to know whether an
/// expression will actually be a boolean.
abstract class TypeHint {
  const TypeHint();
}

class IsBoolean extends TypeHint {
  const IsBoolean();
}

class IsDateTime extends TypeHint {
  const IsDateTime();
}
