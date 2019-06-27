part of '../analysis.dart';

/// A type that sql expressions can have at runtime.
abstract class SqlType {
  const SqlType();
  const factory SqlType.nullType() = NullType._;
  const factory SqlType.int() = IntegerType._;
  const factory SqlType.real() = RealType._;
  const factory SqlType.text() = TextType._;
  const factory SqlType.blob() = BlobType._;

  bool isSubTypeOf(SqlType other);
}

class NullType extends SqlType {
  const NullType._();

  @override
  bool isSubTypeOf(SqlType other) => true;
}

class IntegerType extends SqlType {
  const IntegerType._();

  @override
  bool isSubTypeOf(SqlType other) => other is IntegerType;
}

class RealType extends SqlType {
  const RealType._();

  @override
  bool isSubTypeOf(SqlType other) => other is RealType;
}

class TextType extends SqlType {
  const TextType._();

  @override
  bool isSubTypeOf(SqlType other) => other is TextType;
}

class BlobType extends SqlType {
  const BlobType._();

  @override
  bool isSubTypeOf(SqlType other) => other is BlobType;
}

class AnyNumericType extends SqlType {
  const AnyNumericType();

  @override
  bool isSubTypeOf(SqlType other) {
    return other is RealType || other is IntegerType;
  }
}

/// Provides more precise hints than the [SqlType]. For instance, booleans are
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
